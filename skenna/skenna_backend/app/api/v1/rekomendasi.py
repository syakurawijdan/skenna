from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.rekomendasi import RekomendasiRequest, RekomendasiResponse
from app.services.rekomendasi_service import get_rekomendasi

router = APIRouter()


@router.post("", response_model=RekomendasiResponse)
@router.post("/rekomendasi-produk", response_model=RekomendasiResponse)
async def rekomendasi_produk(req: RekomendasiRequest, db: Session = Depends(get_db)):
    return await get_rekomendasi(
        req.kategori,
        req.sodium_mg,
        user_id=req.user_id,
        db=db,
        product_name=req.product_name,
        jumlah=1,
    )
