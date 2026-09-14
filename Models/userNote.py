from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from database import Base

class UserNote(Base):
    __tablename__ = "UserNotes"

    idUserNotes = Column(Integer, primary_key=True, nullable=False, index=True)
    idUser = Column(Integer, ForeignKey("User.idUser"))
    note = Column(String)
    name = Column(String(100), nullable=False)

    user = relationship("User", back_populates="notes")


