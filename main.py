from dotenv import load_dotenv
load_dotenv()

import os
print("REDIRECT URI IS:", os.environ.get("WORKOS_REDIRECT_URI"))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from database import Base
from Controllers import userNotes, users, molecules, atoms, bonds, molNotes, auth

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from Models.user import User

from Models.userNote import UserNote
from Models.molecule import Molecule
from Models.molNote import MolNote
from Models.atom import Atom
from Models.bond import Bond


Base.metadata.create_all(bind=engine)

app.include_router(users.router)
app.include_router(molecules.router)
app.include_router(atoms.router)
app.include_router(bonds.router)
app.include_router(userNotes.router)
app.include_router(molNotes.router)

app.include_router(auth.router)