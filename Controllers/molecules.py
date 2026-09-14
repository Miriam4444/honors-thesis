from fastapi import APIRouter
from database import SessionLocal
from Models.molecule import Molecule
from schemas import MoleculeCreate, MoleculeUpdate

router = APIRouter()

@router.post("/molecules")
def create_molecule(molecule: MoleculeCreate):
    db = SessionLocal()
    try:
        new_molecule = Molecule(
            name=molecule.name,
            idUser=molecule.idUser
        )
        db.add(new_molecule)
        db.commit()
        db.refresh(new_molecule)
        return {"message": "Molecule created!", "idMolecule": new_molecule.idMolecule, "name": new_molecule.name}
    finally:
        db.close()

@router.get("/molecules/{user_id}")
def get_molecules(user_id: int):
    db = SessionLocal()
    try:
        molecules = db.query(Molecule).filter(Molecule.idUser == user_id).all()
        return [{"idMolecule": m.idMolecule, "name": m.name, "idUser": m.idUser} for m in molecules]
    finally:
        db.close()

@router.put("/molecules/{molecule_id}")
def update_molecule(molecule_id: int, molecule: MoleculeUpdate):
    db = SessionLocal()
    try:
        existing_molecule = db.query(Molecule).filter(Molecule.idMolecule == molecule_id).first()
        if not existing_molecule:
            return {"message": "Molecule not found"}
        existing_molecule.name = molecule.name
        db.commit()
        return {"message": "Molecule updated!"}
    finally:
        db.close()

@router.delete("/molecules/{molecule_id}")
def delete_molecule(molecule_id: int):
    db = SessionLocal()
    try:
        molecule = db.query(Molecule).filter(Molecule.idMolecule == molecule_id).first()
        if not molecule:
            return {"message": "Molecule not found"}
        db.delete(molecule)
        db.commit()
        return {"message": "Molecule deleted!"}
    finally:
        db.close()