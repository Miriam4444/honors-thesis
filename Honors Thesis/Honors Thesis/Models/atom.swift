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

