//
//  molecule.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

struct Molecule: Codable {
    let idMolecule: Int
    let idUser: Int
    let name: String
}

struct MoleculeCreate: Codable {
    let idUser: Int
    let name: String
}

extension Molecule {
    static let sample = Molecule (idMolecule : 1, idUser: 1, name: "Water")
}


