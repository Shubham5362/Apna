import os
import uuid
from typing import List, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.shop import Shop
from app.schemas.shop import ShopCreate, ShopUpdate, ShopResponse

router = APIRouter()

UPLOAD_DIR = "uploads/shops"


def get_shop_image_url(image_path: str | None) -> str | None:
    if not image_path:
        return None
    return f"/static/shops/{os.path.basename(image_path)}"


@router.post("", response_model=ShopResponse, status_code=status.HTTP_201_CREATED)
def create_shop(
    shop_in: ShopCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Create a new shop for the authenticated user.
    A user can only own one shop.
    """
    # Check if user already owns a shop
    existing_shop = db.query(Shop).filter(Shop.owner_id == current_user.id).first()
    if existing_shop:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You already own a shop. Only one shop per user is allowed.",
        )

    shop = Shop(
        name=shop_in.name,
        description=shop_in.description,
        owner_id=current_user.id,
        is_active=True,
    )
    db.add(shop)
    db.commit()
    db.refresh(shop)

    return ShopResponse(
        id=shop.id,
        name=shop.name,
        description=shop.description,
        owner_id=shop.owner_id,
        image_url=get_shop_image_url(shop.image_path),
        is_active=shop.is_active,
        created_at=shop.created_at,
        updated_at=shop.updated_at,
    )


@router.get("", response_model=List[ShopResponse])
def read_shops(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100
) -> Any:
    """
    Retrieve all shops.
    """
    shops = db.query(Shop).offset(skip).limit(limit).all()
    return [
        ShopResponse(
            id=s.id,
            name=s.name,
            description=s.description,
            owner_id=s.owner_id,
            image_url=get_shop_image_url(s.image_path),
            is_active=s.is_active,
            created_at=s.created_at,
            updated_at=s.updated_at,
        )
        for s in shops
    ]


@router.get("/{id}", response_model=ShopResponse)
def read_shop_by_id(
    id: int,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get a specific shop by ID.
    """
    shop = db.query(Shop).filter(Shop.id == id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shop not found.",
        )

    return ShopResponse(
        id=shop.id,
        name=shop.name,
        description=shop.description,
        owner_id=shop.owner_id,
        image_url=get_shop_image_url(shop.image_path),
        is_active=shop.is_active,
        created_at=shop.created_at,
        updated_at=shop.updated_at,
    )


@router.put("/{id}", response_model=ShopResponse)
def update_shop(
    id: int,
    shop_in: ShopUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update a shop. Only the shop owner can edit it.
    """
    shop = db.query(Shop).filter(Shop.id == id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shop not found.",
        )

    if shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to update this shop.",
        )

    update_data = shop_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(shop, field, value)

    db.commit()
    db.refresh(shop)

    return ShopResponse(
        id=shop.id,
        name=shop.name,
        description=shop.description,
        owner_id=shop.owner_id,
        image_url=get_shop_image_url(shop.image_path),
        is_active=shop.is_active,
        created_at=shop.created_at,
        updated_at=shop.updated_at,
    )


@router.delete("/{id}", response_model=ShopResponse)
def delete_shop(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Delete a shop. Only the shop owner can delete it.
    """
    shop = db.query(Shop).filter(Shop.id == id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shop not found.",
        )

    if shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to delete this shop.",
        )

    # Delete local image file if it exists
    if shop.image_path and os.path.exists(shop.image_path):
        try:
            os.remove(shop.image_path)
        except Exception:
            pass

    db.delete(shop)
    db.commit()

    return ShopResponse(
        id=shop.id,
        name=shop.name,
        description=shop.description,
        owner_id=shop.owner_id,
        image_url=None,
        is_active=shop.is_active,
        created_at=shop.created_at,
        updated_at=shop.updated_at,
    )


@router.post("/{id}/photo", response_model=ShopResponse)
async def upload_shop_photo(
    id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Upload and update the shop photo. Only the shop owner can upload it.
    """
    shop = db.query(Shop).filter(Shop.id == id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shop not found.",
        )

    if shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to update this shop's photo.",
        )

    # 1. Validate MIME type
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image.",
        )

    # 2. Validate file extension
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp", ".gif"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format. Allowed: JPG, JPEG, PNG, WEBP, GIF.",
        )

    # 3. Save file locally
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    unique_filename = f"{uuid.uuid4().hex}{ext}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)

    try:
        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Could not save shop photo: {str(e)}",
        )

    # Delete old file if exists
    if shop.image_path and os.path.exists(shop.image_path):
        try:
            os.remove(shop.image_path)
        except Exception:
            pass

    shop.image_path = file_path
    db.commit()
    db.refresh(shop)

    return ShopResponse(
        id=shop.id,
        name=shop.name,
        description=shop.description,
        owner_id=shop.owner_id,
        image_url=get_shop_image_url(shop.image_path),
        is_active=shop.is_active,
        created_at=shop.created_at,
        updated_at=shop.updated_at,
    )
