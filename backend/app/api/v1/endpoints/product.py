import os
import uuid
from typing import List, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.shop import Shop
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductUpdate, ProductResponse

router = APIRouter()

UPLOAD_DIR = "uploads/products"


def get_product_image_url(image_path: str | None) -> str | None:
    if not image_path:
        return None
    return f"/static/products/{os.path.basename(image_path)}"


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    product_in: ProductCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Create a new product. Only the shop owner can create products.
    """
    # 1. Check if shop exists
    shop = db.query(Shop).filter(Shop.id == product_in.shop_id).first()
    if not shop:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shop not found.",
        )

    # 2. Check if current user is owner of the shop
    if shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to add products to this shop.",
        )

    product = Product(
        name=product_in.name,
        description=product_in.description,
        category=product_in.category,
        price=product_in.price,
        stock=product_in.stock,
        shop_id=product_in.shop_id,
        is_active=True,
    )
    db.add(product)
    db.commit()
    db.refresh(product)

    return ProductResponse(
        id=product.id,
        name=product.name,
        description=product.description,
        category=product.category,
        price=product.price,
        stock=product.stock,
        image_url=get_product_image_url(product.image_path),
        is_active=product.is_active,
        shop_id=product.shop_id,
        created_at=product.created_at,
        updated_at=product.updated_at,
    )


@router.get("", response_model=List[ProductResponse])
def read_products(
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    category: Optional[str] = None,
    shop_id: Optional[int] = None,
    sort_by: str = Query("latest", description="Sorting option: latest, price_low_high, price_high_low")
) -> Any:
    """
    Retrieve all products with optional filters, search, and sorting.
    """
    query = db.query(Product)

    # Apply filters
    if search:
        query = query.filter(Product.name.ilike(f"%{search}%"))
    if category:
        query = query.filter(Product.category.ilike(category))
    if shop_id:
        query = query.filter(Product.shop_id == shop_id)

    # Apply sorting
    if sort_by == "price_low_high":
        query = query.order_by(Product.price.asc())
    elif sort_by == "price_high_low":
        query = query.order_by(Product.price.desc())
    else:  # "latest" or default
        query = query.order_by(Product.created_at.desc())

    products = query.offset(skip).limit(limit).all()

    return [
        ProductResponse(
            id=p.id,
            name=p.name,
            description=p.description,
            category=p.category,
            price=p.price,
            stock=p.stock,
            image_url=get_product_image_url(p.image_path),
            is_active=p.is_active,
            shop_id=p.shop_id,
            created_at=p.created_at,
            updated_at=p.updated_at,
        )
        for p in products
    ]


@router.get("/{id}", response_model=ProductResponse)
def read_product_by_id(
    id: int,
    db: Session = Depends(get_db)
) -> Any:
    """
    Get a specific product by ID.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )

    return ProductResponse(
        id=product.id,
        name=product.name,
        description=product.description,
        category=product.category,
        price=product.price,
        stock=product.stock,
        image_url=get_product_image_url(product.image_path),
        is_active=product.is_active,
        shop_id=product.shop_id,
        created_at=product.created_at,
        updated_at=product.updated_at,
    )


@router.put("/{id}", response_model=ProductResponse)
def update_product(
    id: int,
    product_in: ProductUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update a product. Only the shop owner can edit it.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )

    # Resolve shop associated with this product
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    if not shop or shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to update this product.",
        )

    update_data = product_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)

    db.commit()
    db.refresh(product)

    return ProductResponse(
        id=product.id,
        name=product.name,
        description=product.description,
        category=product.category,
        price=product.price,
        stock=product.stock,
        image_url=get_product_image_url(product.image_path),
        is_active=product.is_active,
        shop_id=product.shop_id,
        created_at=product.created_at,
        updated_at=product.updated_at,
    )


@router.delete("/{id}", response_model=ProductResponse)
def delete_product(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Delete a product. Only the shop owner can delete it.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )

    # Resolve shop associated with this product
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    if not shop or shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to delete this product.",
        )

    # Delete local image file if it exists
    if product.image_path and os.path.exists(product.image_path):
        try:
            os.remove(product.image_path)
        except Exception:
            pass

    db.delete(product)
    db.commit()

    return ProductResponse(
        id=product.id,
        name=product.name,
        description=product.description,
        category=product.category,
        price=product.price,
        stock=product.stock,
        image_url=None,
        is_active=product.is_active,
        shop_id=product.shop_id,
        created_at=product.created_at,
        updated_at=product.updated_at,
    )


@router.post("/{id}/photo", response_model=ProductResponse)
async def upload_product_photo(
    id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Upload and update the product photo. Only the shop owner can upload it.
    """
    product = db.query(Product).filter(Product.id == id).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found.",
        )

    # Resolve shop associated with this product
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    if not shop or shop.owner_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to update this product's photo.",
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
            detail=f"Could not save product photo: {str(e)}",
        )

    # Delete old file if exists
    if product.image_path and os.path.exists(product.image_path):
        try:
            os.remove(product.image_path)
        except Exception:
            pass

    product.image_path = file_path
    db.commit()
    db.refresh(product)

    return ProductResponse(
        id=product.id,
        name=product.name,
        description=product.description,
        category=product.category,
        price=product.price,
        stock=product.stock,
        image_url=get_product_image_url(product.image_path),
        is_active=product.is_active,
        shop_id=product.shop_id,
        created_at=product.created_at,
        updated_at=product.updated_at,
    )
