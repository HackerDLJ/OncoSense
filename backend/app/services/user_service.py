import secrets
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import hash_password, verify_password
from app.models.user import User
from app.schemas.user import UserCreate


def get_user_by_email(db: Session, email: str) -> User | None:
    normalized_email = email.strip().lower()
    return db.query(User).filter(User.email == normalized_email).first()


def get_user_by_google_id(db: Session, google_id: str) -> User | None:
    return db.query(User).filter(User.google_id == google_id).first()


def create_user(db: Session, user: UserCreate, google_id: str | None = None, is_verified: bool = False) -> User:
    normalized_email = str(user.email).strip().lower()

    existing = get_user_by_email(db, normalized_email)
    if existing:
        if google_id and existing.google_id is None:
            existing.google_id = google_id
            existing.is_verified = existing.is_verified or is_verified
            db.commit()
            db.refresh(existing)
            return existing
        raise ValueError("User already exists")

    db_user = User(
        name=user.name.strip(),
        email=normalized_email,
        hashed_password=hash_password(user.password),
        role="patient",
        is_active=True,
        is_verified=is_verified,
        google_id=google_id,
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not user.is_active:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def get_or_create_google_user(db: Session, email: str, name: str, google_id: str) -> User:
    normalized_email = email.strip().lower()
    user = get_user_by_email(db, normalized_email)

    if user:
        user.google_id = user.google_id or google_id
        user.is_verified = True
        user.name = user.name or name
        db.commit()
        db.refresh(user)
        return user

    return create_user(
        db,
        UserCreate(name=name, email=normalized_email, password=secrets.token_urlsafe(24)),
        google_id=google_id,
        is_verified=True,
    )


def request_password_reset(db: Session, email: str) -> str | None:
    user = get_user_by_email(db, email)
    if not user:
        return None

    reset_token = secrets.token_urlsafe(24)
    user.password_reset_token = reset_token
    user.password_reset_expires_at = datetime.utcnow() + timedelta(minutes=settings.PASSWORD_RESET_TTL_MINUTES)
    db.commit()
    db.refresh(user)
    return reset_token


def reset_password_with_token(db: Session, token: str, new_password: str) -> bool:
    user = (
        db.query(User)
        .filter(User.password_reset_token == token)
        .first()
    )
    if not user:
        return False

    if user.password_reset_expires_at is None or user.password_reset_expires_at < datetime.utcnow():
        return False

    user.hashed_password = hash_password(new_password)
    user.password_reset_token = None
    user.password_reset_expires_at = None
    db.commit()
    return True