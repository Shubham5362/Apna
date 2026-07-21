import os
import uuid
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session

from app.core.deps import get_db, get_current_user
from app.models.user import User
from app.models.user_profile import UserProfile
from app.schemas.user_profile import UserProfileUpdate, UserProfileResponse

router = APIRouter()

UPLOAD_DIR = "uploads/profile_photos"


def calculate_completion(user: User, profile: UserProfile) -> int:
    fields = [
        user.full_name,
        profile.email,
        profile.gender,
        profile.date_of_birth,
        profile.address,
        profile.city,
        profile.state,
        profile.pincode,
        profile.country,
        profile.preferred_language,
        profile.timezone,
        profile.profile_photo_path,
    ]
    filled = sum(
        1 for f in fields if f is not None and str(f).strip() != ""
    )
    return int(round((filled / len(fields)) * 100))


def get_profile_photo_url(photo_path: str | None) -> str | None:
    if not photo_path:
        return None
    return f"/static/profile_photos/{os.path.basename(photo_path)}"


@router.get("", response_model=UserProfileResponse)
def get_current_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Get the authenticated user's profile.
    """
    profile = current_user.profile
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)

    completion = calculate_completion(current_user, profile)
    photo_url = get_profile_photo_url(profile.profile_photo_path)

    return UserProfileResponse(
        user_id=current_user.id,
        phone_number=current_user.phone_number,
        full_name=current_user.full_name,
        email=profile.email,
        gender=profile.gender,
        date_of_birth=profile.date_of_birth,
        address=profile.address,
        city=profile.city,
        state=profile.state,
        pincode=profile.pincode,
        country=profile.country,
        preferred_language=profile.preferred_language,
        timezone=profile.timezone,
        profile_photo_url=photo_url,
        completion_percentage=completion,
    )


@router.put("", response_model=UserProfileResponse)
def update_profile(
    profile_in: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Update the authenticated user's profile.
    """
    profile = current_user.profile
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)

    if profile_in.full_name is not None:
        current_user.full_name = profile_in.full_name

    update_data = profile_in.model_dump(exclude={"full_name"}, exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(current_user)
    db.refresh(profile)

    completion = calculate_completion(current_user, profile)
    photo_url = get_profile_photo_url(profile.profile_photo_path)

    return UserProfileResponse(
        user_id=current_user.id,
        phone_number=current_user.phone_number,
        full_name=current_user.full_name,
        email=profile.email,
        gender=profile.gender,
        date_of_birth=profile.date_of_birth,
        address=profile.address,
        city=profile.city,
        state=profile.state,
        pincode=profile.pincode,
        country=profile.country,
        preferred_language=profile.preferred_language,
        timezone=profile.timezone,
        profile_photo_url=photo_url,
        completion_percentage=completion,
    )


@router.post("/photo", response_model=UserProfileResponse)
async def upload_profile_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Any:
    """
    Upload and update profile photo for the authenticated user.
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an image.",
        )

    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp", ".gif"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format. Allowed: JPG, JPEG, PNG, WEBP, GIF.",
        )

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
            detail=f"Could not save profile photo: {str(e)}",
        )

    profile = current_user.profile
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)

    if profile.profile_photo_path and os.path.exists(profile.profile_photo_path):
        try:
            os.remove(profile.profile_photo_path)
        except Exception:
            pass

    profile.profile_photo_path = file_path
    db.commit()
    db.refresh(profile)
    db.refresh(current_user)

    completion = calculate_completion(current_user, profile)
    photo_url = get_profile_photo_url(profile.profile_photo_path)

    return UserProfileResponse(
        user_id=current_user.id,
        phone_number=current_user.phone_number,
        full_name=current_user.full_name,
        email=profile.email,
        gender=profile.gender,
        date_of_birth=profile.date_of_birth,
        address=profile.address,
        city=profile.city,
        state=profile.state,
        pincode=profile.pincode,
        country=profile.country,
        preferred_language=profile.preferred_language,
        timezone=profile.timezone,
        profile_photo_url=photo_url,
        completion_percentage=completion,
    )
