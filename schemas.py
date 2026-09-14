from pydantic import BaseModel
from enum import Enum

#User stuff
#all the creating classes
class UserBase(BaseModel):
    username: str
    email: str

class UserCreate(UserBase):
    workos_user_id: str

#this is what gets sent back to the frontend
class UserOut(UserBase):
    idUser: int

    class Config:
        from_attributes = True

#Molecule stuff
#Creating molecules
class MoleculeBase(BaseModel):
    name: str
    idUser: int

class MoleculeCreate(MoleculeBase):
    pass

#updating molecules
class MoleculeUpdate(BaseModel):
    name: str

#gets sent back to frontend
class MoleculeOut(MoleculeBase):
    idMolecule: int

    class Config:
        from_attributes = True

#MolNote stuff
class MolNoteBase(BaseModel):
    name: str
    note: str | None = None
    idMolecule: int

class MolNoteCreate(MolNoteBase):
    pass

class MolNoteUpdate(BaseModel):
    name: str
    note: str | None = None

class MolNoteOut(MolNoteBase):
    idMoleculeNotes: int

    class Config:
        from_attributes = True


#Bond stuff
class BondType(str, Enum):
    single = "single"
    double = "double"
    triple = "triple"

class BondBase(BaseModel):
    idAtom1: int | None = None
    idAtom2: int | None = None
    bondType: BondType
    idMolecule: int | None = None

class BondCreate(BondBase):
    pass

class BondUpdate(BaseModel):
    bondType: BondType

class BondOut(BondBase):
    idBond: int

    class Config:
        from_attributes = True

#Atom stuff
class AtomBase(BaseModel):
    name: str
    xcoord: float
    ycoord: float
    zcoord: float
    idMolecule: int | None = None

class AtomCreate(AtomBase):
    pass

class AtomUpdate(BaseModel):
    name: str
    xcoord: float
    ycoord: float
    zcoord: float

class AtomOut(AtomBase):
    idAtom: int

    class Config:
        from_attributes = True

#UserNote stuff
class UserNoteBase(BaseModel):
    name: str
    note: str | None = None
    idUser: int

class UserNoteCreate(UserNoteBase):
    pass

class UserNoteUpdate(BaseModel):
    name: str
    note: str | None = None

class UserNoteOut(UserNoteBase):
    idUserNotes: int

    class Config:
        from_attributes = True