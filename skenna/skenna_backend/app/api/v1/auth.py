import logging
import random
import smtplib
from datetime import datetime, timedelta
from email.message import EmailMessage

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    generate_refresh_token,
    hash_refresh_token,
    verify_password,
    verify_refresh_token_hash,
)
from app.db.session import get_db
from app.models.otp_verification import OtpVerification
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.repositories.user_repository import UserRepository

router = APIRouter()
logger = logging.getLogger(__name__)


class RegisterRequest(BaseModel):
    full_name: str = ""
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class SendOtpRequest(BaseModel):
    email: str
    purpose: str = "register"


class VerifyOtpRequest(BaseModel):
    email: str
    otp: str

class ResetPasswordRequest(BaseModel):
    email: str
    new_password: str


def _refresh_token_expiry(now: datetime) -> datetime:
    return now + timedelta(days=settings.refresh_token_expire_days)


def _find_active_refresh_token(
    db: Session,
    raw_token: str,
    now: datetime | None = None,
) -> RefreshToken | None:
    now = now or datetime.utcnow()
    token_hash = hash_refresh_token(raw_token)
    # The SHA-256 hash is deterministic and indexed, so we can look it up
    # directly without storing the raw secret or scanning the whole table.
    token = db.scalar(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at > now,
        )
    )
    if token is None:
        return None
    if not verify_refresh_token_hash(raw_token, token.token_hash):
        return None
    return token


def _send_otp_email(email: str, otp_code: str) -> None:
    if not settings.smtp_host:
        logger.warning("SMTP_HOST is not configured. OTP for %s: %s", email, otp_code)
        return

    message = EmailMessage()
    message["Subject"] = "Kode OTP SKENNA"
    message["From"] = settings.smtp_from_email or settings.smtp_username
    message["To"] = email
    
    # Plain text fallback
    message.set_content(
        f"Kode OTP SKENNA kamu adalah {otp_code}. "
        "Kode ini berlaku selama 5 menit."
    )
    
    # HTML version
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: auto; 
                background: #ffffff; border-radius: 16px; overflow: hidden;
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
        
        <!-- Header -->
        <div style="background: #2C4A8A; padding: 32px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px; 
                       letter-spacing: 2px;">SKENNA</h1>
            <p style="color: #DFE4ED; margin: 8px 0 0; font-size: 13px;">
                Track Your Sodium
            </p>
        </div>
        
        <!-- Body -->
        <div style="padding: 32px; text-align: center;">
            <p style="color: #213868; font-size: 16px; font-weight: 600;">
                Verifikasi Email Kamu
            </p>
            <p style="color: #5E6B84; font-size: 14px; line-height: 1.6;">
                Gunakan kode OTP berikut untuk verifikasi akun SKENNA kamu.
                Kode berlaku selama <strong>5 menit</strong>.
            </p>
            
            <!-- OTP Box -->
            <div style="background: #DFE4ED; border-radius: 12px; 
                        padding: 24px; margin: 24px 0;">
                <p style="color: #213868; font-size: 13px; margin: 0 0 8px;">
                    Kode OTP kamu
                </p>
                <h2 style="color: #2C4A8A; font-size: 42px; margin: 0; 
                           letter-spacing: 12px; font-weight: 700;">
                    {otp_code}
                </h2>
            </div>
            
            <p style="color: #E53935; font-size: 13px;">
                ⚠️ Jangan bagikan kode ini kepada siapapun!
            </p>
        </div>
        
        <!-- Footer -->
        <div style="background: #F5F7FB; padding: 16px; text-align: center;">
            <p style="color: #8A94A6; font-size: 12px; margin: 0;">
                Email ini dikirim otomatis oleh SKENNA. 
                Jika kamu tidak merasa mendaftar, abaikan email ini.
            </p>
        </div>
    </div>
    """
    message.add_alternative(html, subtype="html")

    with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as smtp:
        if settings.smtp_use_tls:
            smtp.starttls()
        if settings.smtp_username:
            smtp.login(settings.smtp_username, settings.smtp_password)
        smtp.send_message(message)


@router.post("/register")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.scalar(select(User).where(User.email == payload.email))
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email sudah terdaftar",
        )
    user = UserRepository.create_user(
        db,
        full_name=payload.full_name.strip(),
        email=payload.email,
        password=payload.password,
    )
    return {"user_id": user.id, "full_name": user.full_name, "email": user.email}


@router.post("/send-otp")
def send_otp(payload: SendOtpRequest, db: Session = Depends(get_db)):
    email = payload.email.strip().lower()
    existing_user = db.scalar(select(User).where(User.email == email))
    if payload.purpose == "forgot_password" and not existing_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email tidak terdaftar",
        )
    if payload.purpose == "register" and existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email sudah terdaftar",
        )
    otp_code = f"{random.randint(0, 999999):06d}"
    now = datetime.utcnow()

    existing_codes = db.scalars(
        select(OtpVerification).where(
            OtpVerification.email == email,
            OtpVerification.is_used.is_(False),
        )
    ).all()
    for code in existing_codes:
        code.is_used = True

    otp = OtpVerification(
        email=email,
        otp_code=otp_code,
        created_at=now,
        expired_at=now + timedelta(minutes=5),
        is_used=False,
    )
    db.add(otp)
    db.commit()

    try:
        _send_otp_email(email, otp_code)
    except Exception as exc:
        logger.warning("Failed to send OTP email to %s: %s", email, exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengirim OTP",
        )
    return {"message": "OTP sent successfully"}


@router.post("/verify-otp")
def verify_otp(payload: VerifyOtpRequest, db: Session = Depends(get_db)):
    email = payload.email.strip().lower()
    otp = db.scalar(
        select(OtpVerification)
        .where(
            OtpVerification.email == email,
            OtpVerification.is_used.is_(False),
        )
        .order_by(OtpVerification.created_at.desc())
    )

    if otp is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="OTP not found")
    if datetime.utcnow() > otp.expired_at:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP expired")
    if otp.otp_code != payload.otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")

    otp.is_used = True
    db.commit()
    return {"message": "OTP verified"}

@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    email = payload.email.strip().lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email tidak terdaftar",
        )
    if verify_password(payload.new_password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Gunakan password yang berbeda dari sebelumnya",
        )
    UserRepository.update_password(db, email=email, new_password=payload.new_password)
    return {"message": "Password berhasil diganti"}


@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == payload.email))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email tidak terdaftar",
        )
    if not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau password salah",
        )
    access_token = create_access_token(subject=str(user.id))
    raw_refresh_token = generate_refresh_token()
    now = datetime.utcnow()
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=hash_refresh_token(raw_refresh_token),
            created_at=now,
            expires_at=_refresh_token_expiry(now),
        )
    )
    db.commit()
    return {
        "access_token": access_token,
        "refresh_token": raw_refresh_token,
        "token_type": "bearer",
        "user_id": user.id,
    }


@router.post("/refresh")
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    token = _find_active_refresh_token(db, payload.refresh_token)
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token tidak valid atau sudah kedaluwarsa",
        )
    access_token = create_access_token(subject=str(token.user_id))
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/logout")
def logout(payload: LogoutRequest, db: Session = Depends(get_db)):
    token = _find_active_refresh_token(db, payload.refresh_token)
    if token is not None:
        token.revoked_at = datetime.utcnow()
        db.commit()
    return {"message": "Logged out"}
