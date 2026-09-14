from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Molecule(Base):
    __tablename__ = "Molecule"

    idMolecule = Column(Integer, primary_key=True, index=True)
    idUser = Column(Integer, ForeignKey("User.idUser"))
    name = Column(String(100))

    user = relationship("User", back_populates="molecules")
    atoms = relationship("Atom", back_populates="molecule")
    notes = relationship("MolNote", back_populates="molecule")
    bonds = relationship("Bond", back_populates="molecule")