from fastapi import APIRouter
from database import SessionLocal
from Models.molNote import MolNote
from schemas import MolNoteCreate, MolNoteUpdate

router = APIRouter()

@router.post("/molNotes")
def create_mol_note(note: MolNoteCreate):
    db = SessionLocal()
    try:
        new_note = MolNote(
            name=note.name,
            note=note.note,
            idMolecule=note.idMolecule
        )
        db.add(new_note)
        db.commit()
        db.refresh(new_note)
        return {"message": "Note created!", "idMoleculeNotes": new_note.idMoleculeNotes}
    finally:
        db.close()

@router.get("/molNotes/{molecule_id}")
def get_mol_notes(molecule_id: int):
    db = SessionLocal()
    try:
        notes = db.query(MolNote).filter(MolNote.idMolecule == molecule_id).all()
        return [{"idMoleculeNotes": n.idMoleculeNotes, "name": n.name, "note": n.note} for n in notes]
    finally:
        db.close()

@router.put("/molNotes/{note_id}")
def update_mol_note(note_id: int, note: MolNoteUpdate):
    db = SessionLocal()
    try:
        existing_note = db.query(MolNote).filter(MolNote.idMoleculeNotes == note_id).first()
        if not existing_note:
            return {"message": "Note not found"}
        existing_note.name = note.name
        existing_note.note = note.note
        db.commit()
        return {"message": "Note updated!"}
    finally:
        db.close()

@router.delete("/molNotes/{note_id}")
def delete_mol_note(note_id: int):
    db = SessionLocal()
    try:
        note = db.query(MolNote).filter(MolNote.idMoleculeNotes == note_id).first()
        if not note:
            return {"message": "Note not found"}
        db.delete(note)
        db.commit()
        return {"message": "Note deleted!"}
    finally:
        db.close()