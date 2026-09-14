from sqlalchemy import Column, Integer, Enum, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
import enum

class BondType(str, enum.Enum):
    single = "single"
    double = "double"
    triple = "triple"

class Bond(Base):
    __tablename__ = "Bond"

    idBond = Column(Integer, primary_key=True, index=True)
    idAtom1 = Column(Integer, ForeignKey("Atom.idAtom"))
    idAtom2 = Column(Integer, ForeignKey("Atom.idAtom"))
    bondType = Column(Enum(BondType), nullable=False)
    idMolecule = Column(Integer, ForeignKey("Molecule.idMolecule"))

    atom1 = relationship("Atom", foreign_keys=[idAtom1])
    atom2 = relationship("Atom", foreign_keys=[idAtom2])
    molecule = relationship("Molecule", back_populates="bonds")