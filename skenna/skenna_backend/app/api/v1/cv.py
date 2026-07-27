import base64
import logging
import os
import time
import uuid
import io

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.core.deps import get_current_user
from app.models.food_label_scan import FoodLabelScan
from app.models.user import User
from app.schemas.cv import CVScanRequest, CVScanResponse
from app.services.cv_ocr_service import CVOcrService
from app.services.sodium_classifier_service import SodiumClassifierService
from app.models.user_profile import UserProfile
from PIL import Image

router = APIRouter()
logger = logging.getLogger(__name__)
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _product_name_from_raw_text(raw_text: str) -> str:
    for line in (raw_text or "").splitlines():
        cleaned = line.strip()
        if cleaned:
            return cleaned
    return ""


def _compress_image(image_bytes: bytes, max_size: int = 1024) -> bytes:
    img = Image.open(io.BytesIO(image_bytes))
    img.thumbnail((max_size, max_size), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()


@router.post("/scan", response_model=CVScanResponse)
def scan_food_label(
    payload: CVScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> CVScanResponse:
    t_start = time.time()

    saved_image_path = None
    if payload.image_base64:
        filename = f"{uuid.uuid4().hex}.jpg"
        filepath = os.path.join(UPLOAD_DIR, filename)

        # Decode → compress → re-encode
        raw_bytes = base64.b64decode(payload.image_base64)
        compressed_bytes = _compress_image(raw_bytes)

        with open(filepath, "wb") as f:
            f.write(compressed_bytes)
        saved_image_path = f"/uploads/{filename}"

        image_input = base64.b64encode(compressed_bytes).decode("ascii")
    else:
        image_input = payload.image_url or ""

    logger.info(f"⏱️ Save image to disk: {time.time() - t_start:.2f}s")
    t_step = time.time()

    raw_text, sodium_mg, takaran_saji, sajian_per_kemasan, satuan_takaran, nama_produk = CVOcrService.scan_label(image_input)

    logger.info(f"⏱️ CVOcrService.scan_label (Gemini Vision): {time.time() - t_step:.2f}s")

    # ── Short-circuit: kalau OCR gagal baca takaran_saji / sajian_per_kemasan,
    # langsung return null tanpa save ke DB, biar Flutter munculin popup gagal scan ──
    if takaran_saji is None and sajian_per_kemasan is None:
        logger.warning(
            "OCR gagal membaca takaran_saji/sajian_per_kemasan untuk user_id=%s",
            current_user.id,
        )
        return CVScanResponse(
            raw_text=raw_text,
            sodium_mg=sodium_mg,
            sodium_level=None,
            scan_id=None,
            takaran_saji=None,
            sajian_per_kemasan=None,
            satuan_takaran=satuan_takaran,
            image_path=saved_image_path,
        )

    t_step = time.time()

    nama_produk = (nama_produk or "").strip()
    if not nama_produk:
        nama_produk = _product_name_from_raw_text(raw_text)
    if not nama_produk:
        logger.warning(
            "nama_produk is empty after raw_text fallback for scan payload user_id=%s",
            current_user.id,
        )

    user_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if user_profile:
        sodium_level, _, daily_limit_mg, limit_source = SodiumClassifierService.classify_for_profile(sodium_mg, user_profile)
    else:
        sodium_level, _ = SodiumClassifierService.classify(sodium_mg, 2000)

    logger.info(f"⏱️ Classify sodium: {time.time() - t_step:.2f}s")
    t_step = time.time()

    scan = FoodLabelScan(
        user_id=current_user.id,
        image_path=saved_image_path or payload.image_url or "base64_upload",
        raw_text=raw_text,
        sodium_mg=sodium_mg,
        takaran_saji=takaran_saji,
        sajian_per_kemasan=sajian_per_kemasan,
        satuan_takaran=satuan_takaran,
        nama_produk=nama_produk,
        isi_kemasan=takaran_saji * sajian_per_kemasan if takaran_saji and sajian_per_kemasan else None,
        isi_kemasan_satuan=satuan_takaran,
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)

    logger.info(f"⏱️ DB save scan: {time.time() - t_step:.2f}s")
    logger.info(f"⏱️ TOTAL endpoint time: {time.time() - t_start:.2f}s")

    return CVScanResponse(
        raw_text=raw_text,
        sodium_mg=sodium_mg,
        sodium_level=sodium_level,
        scan_id=scan.id,
        takaran_saji=takaran_saji,
        sajian_per_kemasan=sajian_per_kemasan,
        satuan_takaran=satuan_takaran,
        image_path=saved_image_path,
    )


class ScanUpdateRequest(BaseModel):
    nama_produk: str
    kategori: str


@router.patch("/scan/{scan_id}", status_code=200)
def update_scan(scan_id: int, payload: ScanUpdateRequest, db: Session = Depends(get_db)):
    scan = db.get(FoodLabelScan, scan_id)
    if not scan:
        raise HTTPException(status_code=404, detail="Scan tidak ditemukan")
    scan.nama_produk = payload.nama_produk
    scan.kategori = payload.kategori
    db.commit()
    return {"id": scan.id, "message": "ok"}
