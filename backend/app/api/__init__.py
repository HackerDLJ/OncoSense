"""API route package for the backend application."""
from .auth import router as auth_router

__all__ = ["auth_router"]
