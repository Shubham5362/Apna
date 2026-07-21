from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class PaymentCreate(BaseModel):
    order_id: int = Field(..., description="ID of the order to pay for")
    payment_method: str = Field("Mock", description="Payment method, e.g., 'UPI', 'Razorpay', 'Card', 'Mock'")


class PaymentVerify(BaseModel):
    razorpay_order_id: str = Field(..., description="Razorpay order ID returned from creation")
    razorpay_payment_id: str = Field(..., description="Razorpay payment ID returned from checkout")
    razorpay_signature: str = Field(..., description="Signature returned from Razorpay checkout")


class PaymentResponse(BaseModel):
    id: int
    order_id: int
    razorpay_order_id: Optional[str] = None
    razorpay_payment_id: Optional[str] = None
    payment_method: str
    status: str
    amount: float
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
