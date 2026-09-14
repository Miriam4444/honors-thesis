from fastapi import APIRouter
from database import SessionLocal
from Models.userNote import UserNote
from schemas import UserNoteCreate, UserNoteUpdate

router = APIRouter()

@router.post("/userNotes")
def create_user_note(note: UserNoteCreate):
    db = SessionLocal()
    try:
        new_note = UserNote(
            name=note.name,
            note=note.note,
            idUser=note.idUser
        )
        db.add(new_note)
        db.commit()
        db.refresh(new_note)
        return {"message": "Note created!", "idUserNotes": new_note.idUserNotes}
    finally:
        db.close()

@router.get("/userNotes/{user_id}")
def get_user_notes(user_id: int):
    db = SessionLocal()
    try:
        notes = db.query(UserNote).filter(UserNote.idUser == user_id).all()
        return [{"idUserNotes": n.idUserNotes, "name": n.name, "note": n.note} for n in notes]
    finally:
        db.close()

@router.put("/userNotes/{note_id}")
def update_user_note(note_id: int, note: UserNoteUpdate):
    db = SessionLocal()
    try:
        existing_note = db.query(UserNote).filter(UserNote.idUserNotes == note_id).first()
        if not existing_note:
            return {"message": "Note not found"}
        existing_note.name = note.name
        existing_note.note = note.note
        db.commit()
        return {"message": "Note updated!"}
    finally:
        db.close()

@router.delete("/userNotes/{note_id}")
def delete_user_note(note_id: int):
    db = SessionLocal()
    try:
        note = db.query(UserNote).filter(UserNote.idUserNotes == note_id).first()
        if not note:
            return {"message": "Note not found"}
        db.delete(note)
        db.commit()
        return {"message": "Note deleted!"}
    finally:
        db.close()