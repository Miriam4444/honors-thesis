from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from database import Base

class MolNote(Base):
    __tablename__ = "MoleculeNotes"

    idMoleculeNotes = Column(Integer, primary_key=True, index=True)
    idMolecule = Column(Integer, ForeignKey("Molecule.idMolecule"))
    note = Column(Text)
    name = Column(String(100), nullable=False)

    molecule = relationship("Molecule", back_populates="notes")