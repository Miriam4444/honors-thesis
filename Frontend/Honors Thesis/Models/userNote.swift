//
//  userNote.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

struct UserNoteCreate: Codable {
    let name: String
    let note: String?
    let idUser: Int
}

struct UserNote: Codable, Identifiable {
    let idUserNotes: Int
    var name: String   //var so a note can be edited in place
    var note: String?
    let idUser: Int?

    var id: Int { idUserNotes }
}
