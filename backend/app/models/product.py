from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(String, nullable=True)
    category = Column(String, nullable=True, index=True)
    price = Column(Float, nullable=False, index=True)
    stock = Column(Integer, default=0, nullable=False)
    image_path = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    shop_id = Column(
        Integer,
        ForeignKey("shops.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    shop = relationship("Shop", back_populates="products")
