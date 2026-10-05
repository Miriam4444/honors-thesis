//
//  MoleculeBuilderVM.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI
import Combine

class MoleculeBuilderVM: ObservableObject {
    @Published var atoms: [Atom] = [] //im initializing a list of Atom objects and it's starting off empty
    @Published var bonds: [Bond] = []
    @Published var selectedBondType: BondType? = nil //initializing a variable tracking which bond type im using and rn its none
    @Published var selectedAtomIDsForBonding: [Int] = [] // im initializing a list of all of the atom ids that im gonna bebonding and its empty rn
    
    //this is just for now bc my frontend isn't connected to my backend yet
    private var nextAtomID = 1
    private var nextBondID = 1
    
    func addAtom(element: String, at position: (x: Float, y: Float, z: Float)) {
        let newAtom = Atom(
            idAtom: nextAtomID, //temporary until i connect to backend
            idMolecule: nil, //temp until i connect to backend
            name: element,
            xcoord: position.x,
            ycoord: position.y,
            zcoord: position.z
        )
        atoms.append(newAtom)
        nextAtomID += 1
    }
    
    func updateAtomPosition(atomID: Int, to position: (x: Float, y: Float, z: Float)) {
        guard let index = atoms.firstIndex(where: { $0.idAtom == atomID }) else { return }
        let atom = atoms[index]
        atoms[index] = Atom(
            idAtom: atom.idAtom,
            idMolecule: atom.idMolecule,
            name: atom.name,
            xcoord: position.x,
            ycoord: position.y,
            zcoord: position.z
        )
    }
    
    func selectAtomForBonding(_ atomID: Int) {
        guard selectedBondType != nil else {
            return
        }
        
        if selectedAtomIDsForBonding.contains(atomID){
            return
        }
        selectedAtomIDsForBonding.append(atomID)
        
        if selectedAtomIDsForBonding.count == 2 {
            createBond()
        }
    }
    
    private func createBond() {
        guard let bondType = selectedBondType,
              selectedAtomIDsForBonding.count == 2 else {
            return
        }
        
        let newBond = Bond(idBond: nextBondID, //temporary
                           idMolecule: nil, //temporary until this bonds molecule is saved
                           idAtom1: selectedAtomIDsForBonding[0],
                           idAtom2: selectedAtomIDsForBonding[1],
                           bondType: bondType
        )
        bonds.append(newBond)
        nextBondID += 1 //temporary until connect to backend
        selectedAtomIDsForBonding = []
    }
    
    func save() {
        //TODO: make this function actually work once backend is connected
    }
}
