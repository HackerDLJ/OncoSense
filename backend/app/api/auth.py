from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database.postgres import get_db
from app.schemas.user import UserCreate, UserLogin
from app.services.user_service import (
    create_user,
    authenticate_user,
)
from app.auth.jwt import create_access_token

router = APIRouter()


@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = create_user(db, user)
    return {
        "message": "User registered successfully",
        "user": {
            "id": db_user.id,
            "name": db_user.name,
            "email": db_user.email,
        },
    }


@router.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = authenticate_user(db, user.email, user.password)

    if not db_user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token({"sub": db_user.email})

    return {
        "access_token": token,
        "token_type": "bearer",
    }