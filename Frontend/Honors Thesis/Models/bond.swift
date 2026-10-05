//
//  bond.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

enum BondType: String, Codable, Hashable {
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

extension Bond {
    static let sampleBond1 = Bond(idBond: 1, idMolecule: 1, idAtom1: 1, idAtom2: 2, bondType: .single)
    static let sampleBond2 = Bond(idBond: 2, idMolecule: 1, idAtom1: 1, idAtom2: 3, bondType: .double)
}
