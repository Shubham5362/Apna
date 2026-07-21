from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator


class CartItemCreate(BaseModel):
    product_id: int = Field(..., description="ID of the product to add to cart")
    quantity: int = Field(1, ge=1, description="Quantity of the product")


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., ge=1, description="Updated quantity")


class CartItemResponse(BaseModel):
    id: int
    product_id: int
    quantity: int
    product_name: str
    product_price: float
    product_image_url: Optional[str] = None

    class Config:
        from_attributes = True


class CartResponse(BaseModel):
    items: List[CartItemResponse]
    total_price: float


class OrderCreate(BaseModel):
    delivery_address: str = Field(..., min_length=1, max_length=255, description="Delivery address for the order")


class OrderItemResponse(BaseModel):
    id: int
    product_id: int
    product_name: str
    quantity: int
    price: float

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    user_id: int
    status: str
    total_price: float
    delivery_address: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    items: List[OrderItemResponse]
    payment_status: str = "Pending"

    class Config:
        from_attributes = True


class OrderStatusUpdate(BaseModel):
    status: str = Field(..., description="Updated order status")

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        valid_statuses = {"Pending", "Confirmed", "Packed", "Shipped", "Delivered", "Cancelled"}
        if v not in valid_statuses:
            raise ValueError(f"Invalid status. Must be one of: {', '.join(valid_statuses)}")
        return v
