from fastapi import APIRouter
from database import SessionLocal
from Models.user import User
from schemas import UserOut

router = APIRouter()

@router.get("/users/{user_id}")
def get_user(user_id: int):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.idUser == user_id).first()
        if not user:
            return {"message": "User not found"}
        return {"idUser": user.idUser, "username": user.username, "email": user.email}
    finally:
        db.close()

@router.put("/users/{user_id}")
def update_user(user_id: int, username: str):
    db = SessionLocal()
    try:
        existing_user = db.query(User).filter(User.idUser == user_id).first()
        if not existing_user:
            return {"message": "User not found"}
        existing_user.username = username
        db.commit()
        return {"message": "User updated!"}
    finally:
        db.close()

@router.delete("/users/{user_id}")
def delete_user(user_id: int):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.idUser == user_id).first()
        if not user:
            return {"message": "User not found"}
        db.delete(user)
        db.commit()
        return {"message": "User deleted!"}
    finally:
        db.close()