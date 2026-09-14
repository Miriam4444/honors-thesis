from pydantic import BaseModel

#all the creating classes
class User(BaseModel):
    username: str
    email: str

class UserCreate(User):
    workos_user_id: str

#this is what gets sent back to the frontend
class UserOut(User):
    idUser: int

    class Config:
        from_attributes = True
