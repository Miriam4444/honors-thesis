from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "User"

    idUser = Column(Integer, primary_key=True, index=True)
    username = Column(String(45), unique=True)
    email = Column(String(100), unique=True)
    workos_user_id = Column(String(100), unique=True)

    #define what the user can have and make it back populate to the user
    notes = relationship("UserNote", back_populates="user")
    molecules = relationship("Molecule", back_populates="user")