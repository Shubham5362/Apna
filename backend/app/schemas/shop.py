from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ShopCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Name of the shop")
    description: Optional[str] = Field(None, max_length=500, description="Description of the shop")


class ShopUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Updated name of the shop")
    description: Optional[str] = Field(None, max_length=500, description="Updated description of the shop")
    is_active: Optional[bool] = Field(None, description="Enable or disable the shop")


class ShopResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    owner_id: int
    image_url: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
