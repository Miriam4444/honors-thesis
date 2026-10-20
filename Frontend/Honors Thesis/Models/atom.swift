//
//  atom.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

struct Atom: Codable {
    let idAtom: Int
    let idMolecule: Int?
    let name: String
    let xcoord: Float
    let ycoord: Float
    let zcoord: Float
}

struct AtomCreate: Codable {
    let idMolecule: Int?
    let name: String
    let xcoord: Float
    let ycoord: Float
    let zcoord: Float
}

//extension Atom {
//    static let sampleOxygen = Atom(idAtom: 1, idMolecule: 1, name: "O", xcoord: 0.0, ycoord: 0.0, zcoord: 0.0)
//    static let sampleHydrogen1 = Atom(idAtom: 2, idMolecule: 1, name: "H", xcoord: 1.0, ycoord: 1.5, zcoord: 1.0)
//    static let sampleHydrogen2 = Atom(idAtom: 3, idMolecule: 1, name: "H", xcoord: -1.0, ycoord: 1.0, zcoord: -1.0)
//}
