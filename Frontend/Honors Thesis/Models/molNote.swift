//
//  molNote.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

struct MolNoteCreate: Codable {
    let name: String
    let note: String?
    let idMolecule: Int
}

struct MolNote: Codable {
    let name: String
    let note: String?
    let idMolecule: Int
}
