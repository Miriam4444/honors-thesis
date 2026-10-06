//
//  MoleculeService.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/5/26.
//

//  Saves a whole molecule to the backend using the /molecules, /atoms and /bonds routes.

import Foundation

// what the backend sends back after creating things (it also sends a "message", which we ignore)
private struct MoleculeCreatedResponse: Decodable { let idMolecule: Int }
private struct AtomCreatedResponse: Decodable { let idAtom: Int }
private struct BondCreatedResponse: Decodable { let idBond: Int }

struct MoleculeService {

    // saves in order: molecule -> atoms -> bonds, and returns the new molecule's id
    static func save(name: String, userID: Int, atoms: [Atom], bonds: [Bond]) async throws -> Int {
        // 1. the molecule itself, so we get an idMolecule to attach everything to
        let molecule: MoleculeCreatedResponse = try await APIClient.post(
            "molecules",
            body: MoleculeCreate(idUser: userID, name: name)
        )

        // 2. the atoms. the app made up its own atom ids (1, 2, 3...) but the database
        // gives each atom a real id, so remember which app id became which database id
        var databaseAtomID: [Int: Int] = [:] // app atom id -> database atom id
        for atom in atoms {
            let created: AtomCreatedResponse = try await APIClient.post(
                "atoms",
                body: AtomCreate(
                    idMolecule: molecule.idMolecule,
                    name: atom.name,
                    xcoord: atom.xcoord,
                    ycoord: atom.ycoord,
                    zcoord: atom.zcoord
                )
            )
            databaseAtomID[atom.idAtom] = created.idAtom
        }

        // 3. the bonds, pointing at the real database atom ids
        for bond in bonds {
            guard let atom1 = databaseAtomID[bond.idAtom1],
                  let atom2 = databaseAtomID[bond.idAtom2] else { continue }
            let _: BondCreatedResponse = try await APIClient.post(
                "bonds",
                body: BondCreate(
                    idMolecule: molecule.idMolecule,
                    idAtom1: atom1,
                    idAtom2: atom2,
                    bondType: bond.bondType
                )
            )
        }

        return molecule.idMolecule
    }
}
