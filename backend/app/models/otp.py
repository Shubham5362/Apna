from sqlalchemy import Column, Integer, String, Boolean, DateTime, func
from app.core.database import Base


class OTPVerification(Base):
    __tablename__ = "otp_verifications"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String, index=True, nullable=False)
    otp = Column(String, nullable=False)
    attempts = Column(Integer, default=0, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
