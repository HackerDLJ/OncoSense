from datetime import datetime, timedelta
from jose import jwt

from app.core.config import settings


def create_access_token(data: dict):
    payload = data.copy()
    expire = datetime.utcnow() + timedelta(
        minutes=settings.JWT_EXPIRE_MINUTES
    )

    payload.update({"exp": expire})

    return jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )