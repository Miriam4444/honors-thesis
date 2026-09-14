from sqlalchemy import Column, Integer, String, Float, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class Atom(Base):
    __tablename__ = "Atom"

    idAtom = Column(Integer, primary_key=True, index=True)
    idMolecule = Column(Integer, ForeignKey("Molecule.idMolecule"))
    name = Column(String(45), nullable=False)
    xcoord = Column(Float, nullable=False)
    ycoord = Column(Float, nullable=False)
    zcoord = Column(Float, nullable=False)

    molecule = relationship("Molecule", back_populates="atoms")