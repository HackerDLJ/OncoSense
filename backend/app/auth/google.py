from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import httpx

router = APIRouter(prefix="/auth", tags=["Authentication"])

class GoogleToken(BaseModel):
    token: str

@router.post("/google")
async def google_login(payload: GoogleToken):
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://oauth2.googleapis.com/tokeninfo?id_token={payload.token}"
        )

    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Invalid Google token")

    data = response.json()

    return {
        "email": data.get("email"),
        "name": data.get("name"),
        "picture": data.get("picture"),
        "provider": "google",
    }