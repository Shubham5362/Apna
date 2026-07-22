import re
from pydantic import BaseModel, Field, field_validator
from typing import Optional


class UserRegistration(BaseModel):
    phone_number: str = Field(..., description="Mobile number starting with + or containing 10-15 digits")
    full_name: Optional[str] = Field(None, description="Full name of the user")

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        # Strip whitespaces and hyphens
        cleaned = re.sub(r"[\s\-]", "", v)
        # Regex to validate phone number: optionally starting with +, then 10 to 15 digits
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError(
                "Invalid phone number format. It must optionally start with '+' followed by 10 to 15 digits."
            )
        return cleaned


class UserSignup(BaseModel):
    phone_number: str = Field(..., description="Mobile number starting with + or containing 10-15 digits")
    full_name: str = Field(..., description="Full name of the user")
    password: str = Field(..., min_length=6, description="Password must be at least 6 characters")
    otp: str = Field(..., min_length=6, max_length=6, description="6-digit OTP code")

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError(
                "Invalid phone number format. It must optionally start with '+' followed by 10 to 15 digits."
            )
        return cleaned


class UserPasswordLogin(BaseModel):
    phone_number: str = Field(..., description="Mobile number")
    password: str = Field(..., description="Password")

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError("Invalid phone number format.")
        return cleaned


class ForgotPasswordRequest(BaseModel):
    phone_number: str = Field(..., description="Mobile number")

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError("Invalid phone number format.")
        return cleaned


class ForgotPasswordVerify(BaseModel):
    phone_number: str = Field(...)
    otp: str = Field(..., min_length=6, max_length=6)

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError("Invalid phone number format.")
        return cleaned


class ResetPasswordRequest(BaseModel):
    phone_number: str = Field(...)
    otp: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=6)

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError("Invalid phone number format.")
        return cleaned


class UserLoginInit(BaseModel):
    phone_number: str = Field(..., description="Mobile number to send OTP to")

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError(
                "Invalid phone number format. It must optionally start with '+' followed by 10 to 15 digits."
            )
        return cleaned


class OTPVerify(BaseModel):
    phone_number: str = Field(...)
    otp: str = Field(..., min_length=4, max_length=6, description="OTP code received")

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        cleaned = re.sub(r"[\s\-]", "", v)
        pattern = r"^\+?[1-9]\d{9,14}$"
        if not re.match(pattern, cleaned):
            raise ValueError("Invalid phone number format.")
        return cleaned


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: int
    phone_number: str
    full_name: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True


class MessageResponse(BaseModel):
    success: bool
    message: str
