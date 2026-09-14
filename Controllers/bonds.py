from fastapi import APIRouter
from database import SessionLocal
from Models.bond import Bond
from schemas import BondCreate, BondUpdate

router = APIRouter()

@router.post("/bonds")
def create_bond(bond: BondCreate):
    db = SessionLocal()
    try:
        new_bond = Bond(
            idAtom1=bond.idAtom1,
            idAtom2=bond.idAtom2,
            bondType=bond.bondType,
            idMolecule=bond.idMolecule
        )
        db.add(new_bond)
        db.commit()
        db.refresh(new_bond)
        return {"message": "Bond created!", "idBond": new_bond.idBond}
    finally:
        db.close()

@router.get("/bonds/{molecule_id}")
def get_bonds(molecule_id: int):
    db = SessionLocal()
    try:
        bonds = db.query(Bond).filter(Bond.idMolecule == molecule_id).all()
        return [{"idBond": b.idBond, "idAtom1": b.idAtom1, "idAtom2": b.idAtom2, "bondType": b.bondType} for b in bonds]
    finally:
        db.close()

@router.put("/bonds/{bond_id}")
def update_bond(bond_id: int, bond: BondUpdate):
    db = SessionLocal()
    try:
        existing_bond = db.query(Bond).filter(Bond.idBond == bond_id).first()
        if not existing_bond:
            return {"message": "Bond not found"}
        existing_bond.bondType = bond.bondType
        db.commit()
        return {"message": "Bond updated!"}
    finally:
        db.close()

@router.delete("/bonds/{bond_id}")
def delete_bond(bond_id: int):
    db = SessionLocal()
    try:
        bond = db.query(Bond).filter(Bond.idBond == bond_id).first()
        if not bond:
            return {"message": "Bond not found"}
        db.delete(bond)
        db.commit()
        return {"message": "Bond deleted!"}
    finally:
        db.close()