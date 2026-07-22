from datetime import datetime
from typing import Optional, Dict
from pydantic import BaseModel, Field


class ReviewCreate(BaseModel):
    product_id: Optional[int] = Field(None, description="Product ID to review (optional if reviewing a shop)")
    shop_id: Optional[int] = Field(None, description="Shop ID to review (optional if reviewing a product)")
    rating_value: int = Field(..., ge=1, le=5, description="Rating value between 1 and 5")
    comment: str = Field(..., min_length=1, max_length=1000, description="Review comment")


class ReviewUpdate(BaseModel):
    rating_value: Optional[int] = Field(None, ge=1, le=5, description="Updated rating value")
    comment: Optional[str] = Field(None, min_length=1, max_length=1000, description="Updated comment")


class ReviewResponse(BaseModel):
    id: int
    user_id: int
    user_name: Optional[str] = None
    product_id: Optional[int] = None
    shop_id: Optional[int] = None
    rating_value: int
    comment: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class RatingSummaryResponse(BaseModel):
    average_rating: float = Field(0.0, description="Average rating score")
    total_ratings: int = Field(0, description="Total number of ratings")
    star_counts: Dict[int, int] = Field(default_factory=dict, description="Count breakdown per star (1-5)")
