import os
from typing import List, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.product import Product
from app.models.cart import CartItem
from app.models.order import Order, OrderItem
from app.schemas.cart_order import (
    CartItemCreate,
    CartItemUpdate,
    CartResponse,
    CartItemResponse,
    OrderCreate,
    OrderResponse,
    OrderItemResponse,
    OrderStatusUpdate,
)

router = APIRouter()


def get_product_image_url(image_path: str | None) -> str | None:
    if not image_path:
        return None
    return f"/static/products/{os.path.basename(image_path)}"


# --- Cart Endpoints ---


@router.get("/cart", response_model=CartResponse)
def get_cart(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get the authenticated user's cart items and the total price.
    """
    cart_items = db.query(CartItem).filter(CartItem.user_id == current_user.id).all()

    items_response = []
    total_price = 0.0
    for item in cart_items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if product:
            price = product.price
            total_price += price * item.quantity
            items_response.append(
                CartItemResponse(
                    id=item.id,
                    product_id=item.product_id,
                    quantity=item.quantity,
                    product_name=product.name,
                    product_price=price,
                    product_image_url=get_product_image_url(product.image_path),
                )
            )

    return CartResponse(items=items_response, total_price=total_price)


@router.post("/cart", response_model=CartResponse)
def add_to_cart(
    item_in: CartItemCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Add a product to the user's cart. If the product already exists, increments quantity.
    """
    # Verify product exists and is active
    product = db.query(Product).filter(Product.id == item_in.product_id, Product.is_active == True).first()
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Product not found or inactive.",
        )

    # Check stock
    if product.stock < item_in.quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Only {product.stock} units are available in stock.",
        )

    # Check if item already in cart
    existing_item = db.query(CartItem).filter(
        CartItem.user_id == current_user.id,
        CartItem.product_id == item_in.product_id,
    ).first()

    if existing_item:
        new_qty = existing_item.quantity + item_in.quantity
        if product.stock < new_qty:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot add more. Total in cart ({new_qty}) exceeds stock ({product.stock}).",
            )
        existing_item.quantity = new_qty
    else:
        new_item = CartItem(
            user_id=current_user.id,
            product_id=item_in.product_id,
            quantity=item_in.quantity,
        )
        db.add(new_item)

    db.commit()
    return get_cart(current_user=current_user, db=db)


@router.put("/cart/{item_id}", response_model=CartResponse)
def update_cart_item(
    item_id: int,
    item_in: CartItemUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update quantity of a specific item in the cart.
    """
    cart_item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.user_id == current_user.id).first()
    if not cart_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart item not found.",
        )

    product = db.query(Product).filter(Product.id == cart_item.product_id).first()
    if product and product.stock < item_in.quantity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Only {product.stock} units are available in stock.",
        )

    cart_item.quantity = item_in.quantity
    db.commit()
    return get_cart(current_user=current_user, db=db)


@router.delete("/cart/{item_id}", response_model=CartResponse)
def remove_from_cart(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Remove an item from the cart.
    """
    cart_item = db.query(CartItem).filter(CartItem.id == item_id, CartItem.user_id == current_user.id).first()
    if not cart_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Cart item not found.",
        )

    db.delete(cart_item)
    db.commit()
    return get_cart(current_user=current_user, db=db)


@router.delete("/cart", response_model=CartResponse)
def clear_cart(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Clear all items in the user's cart.
    """
    db.query(CartItem).filter(CartItem.user_id == current_user.id).delete()
    db.commit()
    return get_cart(current_user=current_user, db=db)


# --- Order Endpoints ---


@router.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def create_order(
    order_in: OrderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Place an order from the user's current cart.
    Verifies stock, deducts stock, creates the order and order items, then clears cart.
    """
    cart_items = db.query(CartItem).filter(CartItem.user_id == current_user.id).all()
    if not cart_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Your cart is empty. Add products to place an order.",
        )

    # 1. Verify stock and calculate total price
    total_price = 0.0
    items_to_create = []

    for item in cart_items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if not product or not product.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Product with ID {item.product_id} is no longer available.",
            )
        if product.stock < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient stock for {product.name}. Available: {product.stock}.",
            )

        # Deduct stock
        product.stock -= item.quantity
        price = product.price
        total_price += price * item.quantity

        items_to_create.append({
            "product_id": item.product_id,
            "product_name": product.name,
            "quantity": item.quantity,
            "price": price
        })

    # 2. Create Order
    order = Order(
        user_id=current_user.id,
        status="Pending",
        total_price=total_price,
        delivery_address=order_in.delivery_address,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    # 3. Create Order Items
    order_items_response = []
    for item_data in items_to_create:
        order_item = OrderItem(
            order_id=order.id,
            product_id=item_data["product_id"],
            quantity=item_data["quantity"],
            price=item_data["price"],
        )
        db.add(order_item)
        db.commit()
        db.refresh(order_item)

        order_items_response.append(
            OrderItemResponse(
                id=order_item.id,
                product_id=order_item.product_id,
                product_name=item_data["product_name"],
                quantity=order_item.quantity,
                price=order_item.price,
            )
        )

    # 4. Clear the user's cart
    db.query(CartItem).filter(CartItem.user_id == current_user.id).delete()
    db.commit()

    return OrderResponse(
        id=order.id,
        user_id=order.user_id,
        status=order.status,
        total_price=order.total_price,
        delivery_address=order.delivery_address,
        created_at=order.created_at,
        updated_at=order.updated_at,
        items=order_items_response,
    )


@router.get("/orders", response_model=List[OrderResponse])
def read_orders(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Retrieve all orders placed by the current user.
    """
    orders = db.query(Order).filter(Order.user_id == current_user.id).order_by(Order.created_at.desc()).all()

    response = []
    for order in orders:
        items_response = []
        for item in order.items:
            product = db.query(Product).filter(Product.id == item.product_id).first()
            prod_name = product.name if product else "Unknown Product"
            items_response.append(
                OrderItemResponse(
                    id=item.id,
                    product_id=item.product_id,
                    product_name=prod_name,
                    quantity=item.quantity,
                    price=item.price,
                )
            )
        response.append(
            OrderResponse(
                id=order.id,
                user_id=order.user_id,
                status=order.status,
                total_price=order.total_price,
                delivery_address=order.delivery_address,
                created_at=order.created_at,
                updated_at=order.updated_at,
                items=items_response,
            )
        )
    return response


@router.get("/orders/{order_id}", response_model=OrderResponse)
def read_order_by_id(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Retrieve details of a specific order by ID.
    """
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found.",
        )

    items_response = []
    for item in order.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        prod_name = product.name if product else "Unknown Product"
        items_response.append(
            OrderItemResponse(
                id=item.id,
                product_id=item.product_id,
                product_name=prod_name,
                quantity=item.quantity,
                price=item.price,
            )
        )

    return OrderResponse(
        id=order.id,
        user_id=order.user_id,
        status=order.status,
        total_price=order.total_price,
        delivery_address=order.delivery_address,
        created_at=order.created_at,
        updated_at=order.updated_at,
        items=items_response,
    )


@router.put("/orders/{order_id}/status", response_model=OrderResponse)
def update_order_status(
    order_id: int,
    status_in: OrderStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update status of an order. For demonstration purposes, any authenticated user can update status.
    """
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found.",
        )

    order.status = status_in.status
    db.commit()
    db.refresh(order)

    return read_order_by_id(order_id=order_id, current_user=current_user, db=db)
