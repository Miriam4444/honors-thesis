//
//  molNote.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

import Foundation

struct MolNoteCreate: Codable {
    let name: String
    let note: String?
    let idMolecule: Int
}

struct MolNote: Codable, Identifiable {
    var idMoleculeNotes: Int?
    let name: String
    let note: String?
    var idMolecule: Int?

    //temporary id for notes that aren't saved yet so lists can still show them
    var localID = UUID()
    var id: String { idMoleculeNotes.map { "db-\($0)" } ?? "local-\(localID)" }

    private enum CodingKeys: String, CodingKey { case idMoleculeNotes, name, note, idMolecule }
}
