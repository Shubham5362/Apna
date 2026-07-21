from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, description="Name of the product")
    description: Optional[str] = Field(None, max_length=500, description="Description of the product")
    category: Optional[str] = Field(None, max_length=100, description="Category of the product")
    price: float = Field(..., gt=0, description="Price of the product")
    stock: int = Field(0, ge=0, description="Stock available")
    shop_id: int = Field(..., description="The ID of the shop this product belongs to")


class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=100)
    price: Optional[float] = Field(None, gt=0)
    stock: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = Field(None)


class ProductResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    price: float
    stock: int
    image_url: Optional[str] = None
    is_active: bool
    shop_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
