from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.rating_review import Rating, Review
from app.schemas.rating_review import ReviewCreate, ReviewUpdate, ReviewResponse, RatingSummaryResponse

router = APIRouter()


@router.post("/reviews", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
def create_review(
    review_in: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Create a new rating and review for a product or a shop.
    A user can only submit one review per product or per shop.
    """
    if not review_in.product_id and not review_in.shop_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either product_id or shop_id must be provided.",
        )
    if review_in.product_id and review_in.shop_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide either product_id or shop_id, not both.",
        )

    # Check for existing review
    if review_in.product_id:
        existing = db.query(Review).filter(
            Review.user_id == current_user.id,
            Review.product_id == review_in.product_id,
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You have already reviewed this product.",
            )
    else:
        existing = db.query(Review).filter(
            Review.user_id == current_user.id,
            Review.shop_id == review_in.shop_id,
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You have already reviewed this shop.",
            )

    try:
        # 1. Create Rating
        rating = Rating(
            user_id=current_user.id,
            product_id=review_in.product_id,
            shop_id=review_in.shop_id,
            rating_value=review_in.rating_value,
        )
        db.add(rating)
        db.flush()

        # 2. Create Review
        review = Review(
            user_id=current_user.id,
            product_id=review_in.product_id,
            shop_id=review_in.shop_id,
            rating_id=rating.id,
            comment=review_in.comment,
        )
        db.add(review)
        db.commit()
        db.refresh(rating)
        db.refresh(review)
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create rating and review: {str(e)}",
        )

    return ReviewResponse(
        id=review.id,
        user_id=review.user_id,
        user_name=current_user.full_name or "Anonymous",
        product_id=review.product_id,
        shop_id=review.shop_id,
        rating_value=rating.rating_value,
        comment=review.comment,
        created_at=review.created_at,
        updated_at=review.updated_at,
    )


@router.get("/reviews", response_model=List[ReviewResponse])
def get_reviews(
    product_id: Optional[int] = None,
    shop_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
) -> Any:
    """
    Retrieve reviews with optional pagination and filtering.
    """
    query = db.query(Review).options(
        joinedload(Review.user),
        joinedload(Review.rating)
    )
    if product_id:
        query = query.filter(Review.product_id == product_id)
    if shop_id:
        query = query.filter(Review.shop_id == shop_id)

    reviews = query.order_by(Review.created_at.desc()).offset(skip).limit(limit).all()

    response = []
    for r in reviews:
        user_name = r.user.full_name if r.user else "Anonymous"
        rating_val = r.rating.rating_value if r.rating else 0

        response.append(
            ReviewResponse(
                id=r.id,
                user_id=r.user_id,
                user_name=user_name,
                product_id=r.product_id,
                shop_id=r.shop_id,
                rating_value=rating_val,
                comment=r.comment,
                created_at=r.created_at,
                updated_at=r.updated_at,
            )
        )
    return response


@router.put("/reviews/{review_id}", response_model=ReviewResponse)
def update_review(
    review_id: int,
    review_in: ReviewUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update an existing review and its associated rating.
    """
    review = db.query(Review).filter(Review.id == review_id, Review.user_id == current_user.id).first()
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found or unauthorized.",
        )

    if review_in.comment is not None:
        review.comment = review_in.comment

    rating = db.query(Rating).filter(Rating.id == review.rating_id).first()
    if rating and review_in.rating_value is not None:
        rating.rating_value = review_in.rating_value

    db.commit()
    db.refresh(review)
    if rating:
        db.refresh(rating)

    return ReviewResponse(
        id=review.id,
        user_id=review.user_id,
        user_name=current_user.full_name or "Anonymous",
        product_id=review.product_id,
        shop_id=review.shop_id,
        rating_value=rating.rating_value if rating else 0,
        comment=review.comment,
        created_at=review.created_at,
        updated_at=review.updated_at,
    )


@router.delete("/reviews/{review_id}")
def delete_review(
    review_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Delete a review and its corresponding rating.
    """
    review = db.query(Review).filter(Review.id == review_id, Review.user_id == current_user.id).first()
    if not review:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Review not found or unauthorized.",
        )

    rating = db.query(Rating).filter(Rating.id == review.rating_id).first()
    if rating:
        db.delete(rating)
    db.delete(review)
    db.commit()

    return {"success": True, "message": "Review deleted successfully."}


@router.get("/reviews/summary", response_model=RatingSummaryResponse)
def get_rating_summary(
    product_id: Optional[int] = None,
    shop_id: Optional[int] = None,
    db: Session = Depends(get_db)
) -> Any:
    """
    Calculate and return rating summary breakdown.
    """
    query = db.query(Rating)
    if product_id:
        query = query.filter(Rating.product_id == product_id)
    elif shop_id:
        query = query.filter(Rating.shop_id == shop_id)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide either product_id or shop_id.",
        )

    ratings = query.all()
    total_ratings = len(ratings)
    if total_ratings == 0:
        return RatingSummaryResponse(
            average_rating=0.0,
            total_ratings=0,
            star_counts={1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        )

    average_rating = round(sum(r.rating_value for r in ratings) / total_ratings, 2)
    star_counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
    for r in ratings:
        if r.rating_value in star_counts:
            star_counts[r.rating_value] += 1

    return RatingSummaryResponse(
        average_rating=average_rating,
        total_ratings=total_ratings,
        star_counts=star_counts,
    )
