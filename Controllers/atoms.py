from fastapi import APIRouter
from database import SessionLocal
from Models.atom import Atom
from schemas import AtomCreate, AtomUpdate

router = APIRouter()

@router.post("/atoms")
def create_atom(atom: AtomCreate):
    db = SessionLocal()
    try:
        new_atom = Atom(
            name=atom.name,
            xcoord=atom.xcoord,
            ycoord=atom.ycoord,
            zcoord=atom.zcoord,
            idMolecule=atom.idMolecule
        )
        db.add(new_atom)
        db.commit()
        db.refresh(new_atom)
        return {"message": "Atom created!", "idAtom": new_atom.idAtom, "atom": new_atom.name}
    finally:
        db.close()

@router.get("/atoms/{molecule_id}")
def get_atoms(molecule_id: int):
    db = SessionLocal()
    try:
        atoms = db.query(Atom).filter(Atom.idMolecule == molecule_id).all()
        return [{"idAtom": a.idAtom, "name": a.name, "xcoord": a.xcoord, "ycoord": a.ycoord, "zcoord": a.zcoord} for a in atoms]
    finally:
        db.close()

@router.put("/atoms/{atom_id}")
def update_atom(atom_id: int, atom: AtomUpdate):
    db = SessionLocal()
    try:
        existing_atom = db.query(Atom).filter(Atom.idAtom == atom_id).first()
        if not existing_atom:
            return {"message": "Atom not found"}
        existing_atom.name = atom.name
        existing_atom.xcoord = atom.xcoord
        existing_atom.ycoord = atom.ycoord
        existing_atom.zcoord = atom.zcoord
        db.commit()
        return {"message": "Atom updated!"}
    finally:
        db.close()

@router.delete("/atoms/{atom_id}")
def delete_atom(atom_id: int):
    db = SessionLocal()
    try:
        atom = db.query(Atom).filter(Atom.idAtom == atom_id).first()
        if not atom:
            return {"message": "Atom not found"}
        db.delete(atom)
        db.commit()
        return {"message": "Atom deleted!"}
    finally:
        db.close()