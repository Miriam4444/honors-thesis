//
//  MoleculeService.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/5/26.
//

//everything molecule-related that talks to the backend:
//saving (new or updating), loading, listing, and notes.

import Foundation

//what the backend sends back after creating things
private struct MoleculeCreatedResponse: Decodable { let idMolecule: Int }
private struct AtomCreatedResponse: Decodable { let idAtom: Int }
private struct BondCreatedResponse: Decodable { let idBond: Int }
private struct NoteCreatedResponse: Decodable { let idMoleculeNotes: Int }
private struct MessageResponse: Decodable { let message: String }

//what gets sent to /molecules/validate
private struct ValidateAtom: Encodable { let idAtom: Int; let name: String }
private struct ValidateBond: Encodable { let idAtom1: Int; let idAtom2: Int; let bondType: BondType }
private struct ValidateRequest: Encodable { let atoms: [ValidateAtom]; let bonds: [ValidateBond] }

//what /molecules/validate sends back
struct ValidationIssue: Decodable { let atomId: Int?; let message: String }
struct AtomPosition: Decodable { let atomId: Int; let x: Float; let y: Float; let z: Float }
struct ValidationResult: Decodable {
    let valid: Bool
    let errors: [ValidationIssue]
    let positions: [AtomPosition]?
    let conformers: [Conformer]? //every stable 3D shape the molecule can take, most stable first
    let diagram: DiagramLayouts? //flat 2D layouts for the Lewis + bond-line diagrams
}

//one stable 3D shape of the molecule (like cyclohexane's chair or twist-boat)
struct Conformer: Decodable {
    let name: String           //"Chair", "Twist-boat", or "Shape 2" when there's no special name
    let relativeEnergy: Double //kJ/mol above the most stable shape (0 = the most stable one)
    let positions: [AtomPosition]
    //puckered rings get their own textbook-style perspective drawing (chair, boat...);
    //nil = this shape uses the molecule's normal flat diagram
    let diagram: DiagramLayouts?

    //what the lists show, e.g. "Chair (most stable)" or "Twist-boat (+24.8 kJ/mol)"
    var label: String {
        relativeEnergy < 0.05 ? "\(name) (most stable)" : "\(name) (+\(String(format: "%.1f", relativeEnergy)) kJ/mol)"
    }
}

//one atom's spot in a flat diagram (RDKit units, a bond is about 1.5 long, centered on 0,0)
struct DiagramPoint: Decodable {
    let atomId: Int
    let x: Float
    let y: Float
    let hydrogens: Int? //bond-line only: how many H's got folded into this atom's label (O + 1 = "OH")
    let depth: Float?   //chair/boat drawings only: how close the atom is to you (bigger = closer)
    let straight: Bool? //bond-line only: a carbon in a straight line (C=C=C, C≡C), which gets a dot so it doesn't vanish
    let inRing: Bool?   //chair/boat drawings only: part of the ring (only ring bonds get the bold front edge)
}

extension DiagramLayouts {
    //how close a ring bond is to you, from 0 (farthest) to 1 (closest), for drawing the ring's front edge
    //bold like textbook chair/boat drawings. nil for bonds that aren't part of the ring, and for normal
    //flat diagrams (those draw at normal thickness)
    func closeness(of bond: Bond, kind: DiagramKind) -> Float? {
        let points = kind == .lewis ? lewis : skeletal
        let ring = points.filter { $0.inRing == true }
        let depths = ring.compactMap(\.depth)
        guard let nearest = depths.max(), let farthest = depths.min(), nearest > farthest,
              let d1 = ring.first(where: { $0.atomId == bond.idAtom1 })?.depth,
              let d2 = ring.first(where: { $0.atomId == bond.idAtom2 })?.depth else { return nil }
        return ((d1 + d2) / 2 - farthest) / (nearest - farthest)
    }
}

struct DiagramLayouts: Decodable {
    let lewis: [DiagramPoint]    //every atom, including H
    let skeletal: [DiagramPoint] //no hydrogens, carbons are just corners
}

//what a save hands back so the app knows which database rows belong to this molecule now
struct SaveResult {
    let moleculeID: Int
    let atomDBIDs: [Int]   //database ids of the atoms that were just saved
    let bondDBIDs: [Int]   //database ids of the bonds that were just saved
    let savedNotes: [MolNote] //notes that were waiting for the molecule to exist
}

struct MoleculeService {
    // MARK: - validation
    static func validate(atoms: [Atom], bonds: [Bond]) async throws -> ValidationResult {
        try await APIClient.post(
            "molecules/validate",
            body: ValidateRequest(
                atoms: atoms.map { ValidateAtom(idAtom: $0.idAtom, name: $0.name) },
                bonds: bonds.map { ValidateBond(idAtom1: $0.idAtom1, idAtom2: $0.idAtom2, bondType: $0.bondType) }
            )
        )
    }
    // MARK: - saving

    //new molecule: creates molecule -> atoms -> bonds -> waiting notes
    //existing molecule: renames it, deletes its old atoms/bonds, then saves the current ones (the backend has no "replace all atoms" route, so delete + re-create is the simplest way)
    
    static func save(
        existingMoleculeID: Int?,
        name: String,
        userID: Int,
        atoms: [Atom],
        bonds: [Bond],
        oldAtomDBIDs: [Int],
        oldBondDBIDs: [Int],
        pendingNotes: [MolNote]
    ) async throws -> SaveResult {

        //1. molecule itself
        let moleculeID: Int
        if let existingMoleculeID {
            let _: MessageResponse = try await APIClient.put(
                "molecules/\(existingMoleculeID)",
                body: MoleculeUpdate(name: name)
            )
            // bonds first, because bonds point at atoms
            for bondID in oldBondDBIDs {
                let _: MessageResponse = try await APIClient.delete("bonds/\(bondID)")
            }
            for atomID in oldAtomDBIDs {
                let _: MessageResponse = try await APIClient.delete("atoms/\(atomID)")
            }
            moleculeID = existingMoleculeID
        } else {
            let created: MoleculeCreatedResponse = try await APIClient.post(
                "molecules",
                body: MoleculeCreate(idUser: userID, name: name)
            )
            moleculeID = created.idMolecule
        }

        //2. atoms -> the app uses its own atom ids, but the database gives each atom a real id so remember which app id became which database id
        var databaseAtomID: [Int: Int] = [:] //app atom id -> database atom id
        for atom in atoms {
            let created: AtomCreatedResponse = try await APIClient.post(
                "atoms",
                body: AtomCreate(
                    idMolecule: moleculeID,
                    name: atom.name,
                    xcoord: atom.xcoord,
                    ycoord: atom.ycoord,
                    zcoord: atom.zcoord
                )
            )
            databaseAtomID[atom.idAtom] = created.idAtom
        }

        // 3.bonds, pointing at the real database atom ids
        var bondDBIDs: [Int] = []
        for bond in bonds {
            guard let atom1 = databaseAtomID[bond.idAtom1],
                  let atom2 = databaseAtomID[bond.idAtom2] else { continue }
            let created: BondCreatedResponse = try await APIClient.post(
                "bonds",
                body: BondCreate(
                    idMolecule: moleculeID,
                    idAtom1: atom1,
                    idAtom2: atom2,
                    bondType: bond.bondType
                )
            )
            bondDBIDs.append(created.idBond)
        }

        //4. notes that were added before the molecule was saved
        var savedNotes: [MolNote] = []
        for note in pendingNotes {
            savedNotes.append(try await addNote(name: note.name, text: note.note, moleculeID: moleculeID))
        }

        return SaveResult(
            moleculeID: moleculeID,
            atomDBIDs: Array(databaseAtomID.values),
            bondDBIDs: bondDBIDs,
            savedNotes: savedNotes
        )
    }

    // MARK: - loading

    //all of a user's molecules (just names abd ids, for the home page)
    static func fetchMolecules(userID: Int) async throws -> [Molecule] {
        try await APIClient.get("molecules/\(userID)")
    }

    //everything needed to open a molecule in the builder
    static func loadMolecule(id moleculeID: Int) async throws -> (atoms: [Atom], bonds: [Bond], notes: [MolNote]) {
        async let atoms: [Atom] = APIClient.get("atoms/\(moleculeID)")
        async let bonds: [Bond] = APIClient.get("bonds/\(moleculeID)")
        async let notes: [MolNote] = APIClient.get("molNotes/\(moleculeID)")
        return try await (atoms, bonds, notes)
    }

    // MARK: - notes

    static func addNote(name: String, text: String?, moleculeID: Int) async throws -> MolNote {
        let created: NoteCreatedResponse = try await APIClient.post(
            "molNotes",
            body: MolNoteCreate(name: name, note: text, idMolecule: moleculeID)
        )
        return MolNote(idMoleculeNotes: created.idMoleculeNotes, name: name, note: text, idMolecule: moleculeID)
    }

    static func fetchUserNotes(userID: Int) async throws -> [UserNote] {
        try await APIClient.get("userNotes/\(userID)")
    }
}
