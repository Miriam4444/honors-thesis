//
//  bond.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

enum BondType: String, Codable {
    case single
    case double
    case triple
}

struct Bond: Codable {
    let idBond: Int
    let idMolecule: Int?
    let idAtom1: Int
    let idAtom2: Int
    let bondType: BondType
}

struct BondCreate: Codable {
    let idMolecule: Int
    let idAtom1: Int
    let idAtom2: Int
    let bondType: BondType
}

