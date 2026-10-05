//
//  MoleculeBuilderVM.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI
import Combine

// tracks where the molecule is in the validate -> save flow
enum ValidationState: Equatable {
    case notChecked            // something changed since the last validate
    case valid                 // passed validation, save is unlocked
    case invalid(String)       // failed, the string says why
}

// what a drag moves: just the atom you grabbed, or everything bonded to it
enum MoveMode: String, CaseIterable, Identifiable {
    case atom = "Atom"
    case molecule = "Whole molecule"
    var id: String { rawValue }
}

class MoleculeBuilderVM: ObservableObject {
    static let immersiveSpaceID = "MoleculeSpace" // name of the floating-in-the-room space

    @Published var atoms: [Atom] = [] //im initializing a list of Atom objects and it's starting off empty
    @Published var bonds: [Bond] = []
    @Published var selectedBondType: BondType? = nil //initializing a variable tracking which bond type im using and rn its none
    @Published var selectedAtomIDsForBonding: [Int] = [] // im initializing a list of all of the atom ids that im gonna bebonding and its empty rn
    @Published var validationState: ValidationState = .notChecked
    #if os(visionOS)
    @Published var statusMessage: String = "Tap an element to add it, then grab it to move it"
    #else
    @Published var statusMessage: String = "Drag an element into the space to start"
    #endif
    @Published var moveMode: MoveMode = .atom
    // set by the floating space itself when it really appears/disappears, so the button can't lie
    @Published var isSpaceOpen = false

    //this is just for now bc my frontend isn't connected to my backend yet
    private var nextAtomID = 1
    private var nextBondID = 1

    // save only works after a successful validate
    var canSave: Bool {
        validationState == .valid
    }

    // MARK: - atoms

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
        moleculeChanged()
        statusMessage = "Added \(element). Grab it to move it wherever you want."
    }

    // backup for when drag-and-drop isn't working: tap an element to add it near the middle
    // each new one is nudged over a bit so they don't land exactly on top of each other
    func addAtomNearCenter(element: String) {
        let nudge = Float(atoms.count % 5) * 0.1 - 0.2
        addAtom(element: element, at: (nudge, 0, 0))
    }

    // moving an atom doesn't change the chemistry, so it doesn't reset validation
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

    // used after a drag: saves the new spot for every atom that moved
    func updateAtomPositions(_ positions: [Int: SIMD3<Float>]) {
        for (atomID, position) in positions {
            updateAtomPosition(atomID: atomID, to: (position.x, position.y, position.z))
        }
    }

    // every atom connected to this one through bonds (including itself) = its molecule
    func connectedAtomIDs(startingAt atomID: Int) -> Set<Int> {
        var visited: Set<Int> = [atomID]
        var toVisit = [atomID]
        while let current = toVisit.popLast() {
            for bond in bonds {
                let neighbor: Int?
                if bond.idAtom1 == current { neighbor = bond.idAtom2 }
                else if bond.idAtom2 == current { neighbor = bond.idAtom1 }
                else { neighbor = nil }
                if let neighbor, !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    toVisit.append(neighbor)
                }
            }
        }
        return visited
    }

    // MARK: - bonds

    // tapping the same bond type again turns bond mode off
    func toggleBondType(_ type: BondType) {
        if selectedBondType == type {
            selectedBondType = nil
            statusMessage = "Bond mode off"
        } else {
            selectedBondType = type
            statusMessage = "\(type.rawValue.capitalized) bond: tap two atoms to connect them"
        }
        selectedAtomIDsForBonding = []
    }

    func selectAtomForBonding(_ atomID: Int) {
        guard selectedBondType != nil else {
            statusMessage = "Pick a bond type on the right first"
            return
        }

        // tapping an atom you already picked unpicks it
        if let index = selectedAtomIDsForBonding.firstIndex(of: atomID) {
            selectedAtomIDsForBonding.remove(at: index)
            return
        }
        selectedAtomIDsForBonding.append(atomID)

        if selectedAtomIDsForBonding.count == 2 {
            createBond()
        } else {
            statusMessage = "Now tap a second atom"
        }
    }

    private func createBond() {
        guard let bondType = selectedBondType,
              selectedAtomIDsForBonding.count == 2 else {
            return
        }
        let first = selectedAtomIDsForBonding[0]
        let second = selectedAtomIDsForBonding[1]
        selectedAtomIDsForBonding = []

        // don't allow two bonds between the same pair of atoms
        let alreadyBonded = bonds.contains {
            ($0.idAtom1 == first && $0.idAtom2 == second) ||
            ($0.idAtom1 == second && $0.idAtom2 == first)
        }
        if alreadyBonded {
            statusMessage = "Those two atoms are already bonded"
            return
        }

        let newBond = Bond(idBond: nextBondID, //temporary
                           idMolecule: nil, //temporary until this bonds molecule is saved
                           idAtom1: first,
                           idAtom2: second,
                           bondType: bondType
        )
        bonds.append(newBond)
        nextBondID += 1 //temporary until connect to backend
        moleculeChanged()
        statusMessage = "Added a \(bondType.rawValue) bond"
    }

    // MARK: - validate + save

    // any change to atoms or bonds means you have to validate again before saving
    private func moleculeChanged() {
        validationState = .notChecked
    }

    func validate() {
        //TODO: replace this with the real chemistry validation (Validation/ in the backend)
        // for now: anything with at least one atom passes
        if atoms.isEmpty {
            validationState = .invalid("Add at least one atom first")
            statusMessage = "Add at least one atom first"
        } else {
            validationState = .valid
            statusMessage = "Looks good! You can save now."
        }
    }

    func save() {
        guard canSave else { return }
        //TODO: send the molecule, atoms, and bonds to the backend once it's connected
        statusMessage = "Saved \(atoms.count) atoms and \(bonds.count) bonds (on this device only for now)"
    }

    func clear() {
        atoms = []
        bonds = []
        selectedAtomIDsForBonding = []
        moleculeChanged()
        statusMessage = "Cleared. Add an element to start again"
    }
}
