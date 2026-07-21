from datetime import date
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(None, max_length=100, description="Full name of the user")
    email: Optional[EmailStr] = Field(None, description="Optional email address")
    gender: Optional[str] = Field(None, max_length=20, description="Gender of the user")
    date_of_birth: Optional[date] = Field(None, description="Date of birth (YYYY-MM-DD)")
    address: Optional[str] = Field(None, max_length=255, description="Street address")
    city: Optional[str] = Field(None, max_length=100, description="City")
    state: Optional[str] = Field(None, max_length=100, description="State/Province")
    pincode: Optional[str] = Field(None, max_length=20, description="ZIP/Postal code")
    country: Optional[str] = Field(None, max_length=100, description="Country")
    preferred_language: Optional[str] = Field(None, max_length=50, description="Preferred language")
    timezone: Optional[str] = Field(None, max_length=50, description="Timezone (e.g., UTC, Asia/Kolkata)")


class UserProfileResponse(BaseModel):
    user_id: int
    phone_number: str
    full_name: Optional[str] = None
    email: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: Optional[str] = None
    preferred_language: Optional[str] = None
    timezone: Optional[str] = None
    profile_photo_url: Optional[str] = None
    completion_percentage: int

    class Config:
        from_attributes = True
