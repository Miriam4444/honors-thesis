from fastapi import APIRouter, HTTPException
from database import SessionLocal
from Models.user import User
from schemas import UserOut
from workos import WorkOSClient
import os

router = APIRouter()

workos_client = WorkOSClient(
    api_key=os.environ["WORKOS_API_KEY"],
    client_id=os.environ["WORKOS_CLIENT_ID"],
)


def get_or_create_user(db, workos_user_id: str, email: str) -> User:
    user = db.query(User).filter(User.workos_user_id == workos_user_id).first()

    if user is None:
        user = User(
            username=email,
            email=email,
            workos_user_id=workos_user_id,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


@router.get("/auth/login-url")
def get_login_url():
    url = workos_client.user_management.get_authorization_url(
        provider="authkit",
        redirect_uri=os.environ["WORKOS_REDIRECT_URI"],
    )
    return {"url": url}


@router.get("/auth/callback")
def auth_callback(code: str):
    db = SessionLocal()
    try:
        try:
            auth_response = workos_client.user_management.authenticate_with_code(code=code)
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid or expired code")

        workos_user = auth_response.user
        user = get_or_create_user(
            db=db,
            workos_user_id=workos_user.id,
            email=workos_user.email,
        )

        return {"user_id": user.idUser, "email": user.email}
    finally:
        db.close()