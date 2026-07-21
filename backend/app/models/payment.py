from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(
        Integer,
        ForeignKey("orders.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    razorpay_order_id = Column(String, nullable=True, unique=True, index=True)
    razorpay_payment_id = Column(String, nullable=True, unique=True, index=True)
    razorpay_signature = Column(String, nullable=True)
    payment_method = Column(String, nullable=False, default="Mock")
    status = Column(String, nullable=False, default="Pending")  # 'Pending', 'Success', 'Failed', 'Refunded'
    amount = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    order = relationship("Order", back_populates="payments")
