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

//what gets sent when you edit a note (same for molecule notes and home page notes)
struct NoteUpdate: Codable {
    let name: String
    let note: String?
}

struct MolNote: Codable, Identifiable {
    var idMoleculeNotes: Int?
    var name: String   //var so a note can be edited in place
    var note: String?
    var idMolecule: Int?

    //temporary id for notes that aren't saved yet so lists can still show them
    var localID = UUID()
    var id: String { idMoleculeNotes.map { "db-\($0)" } ?? "local-\(localID)" }

    private enum CodingKeys: String, CodingKey { case idMoleculeNotes, name, note, idMolecule }
}
