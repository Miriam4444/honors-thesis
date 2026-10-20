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
    case notChecked            //like if something changed since the last validate
    case valid                 //like if it passed validation sosave is unlocked
    case invalid(String)       //failed and the string says why
}

//what a drag moves
//either just the atom you grabbed or everything bonded to it
enum MoveMode: String, CaseIterable, Identifiable {
    case atom = "Atom"
    case molecule = "Whole molecule"
    var id: String { rawValue }
}

//which flat diagram the molecule turns into
enum DiagramKind: String, CaseIterable, Identifiable {
    case lewis = "Lewis"
    case bondLine = "Bond-line"
    var id: String { rawValue }
}

class MoleculeBuilderVM: ObservableObject {
    static let immersiveSpaceID = "MoleculeSpace" //this is the name of the floating in the room space
    static let mainWindowID = "main" //the home page window, so vision pro can close/reopen it

    @Published var atoms: [Atom] = [] //im initializing a list of Atom objects and it's starting off empty
    @Published var bonds: [Bond] = []
    @Published var selectedBondType: BondType? = nil //initializing a variable tracking which bond type im using and rn its none
    @Published var selectedAtomIDsForBonding: [Int] = [] // m initializing a list of all of the atom ids that im gonna bebonding and its empty rn
    @Published var validationState: ValidationState = .notChecked
    #if os(visionOS)
    @Published var statusMessage: String = "Tap an element to add it, then grab it to move it"
    #else
    @Published var statusMessage: String = "Drag an element into the space to start"
    #endif
    @Published var moveMode: MoveMode = .atom
    // set by the floating space itself when it really appears/disappears, so the button can't lie
    @Published var isSpaceOpen = false
    @Published var moleculeName = ""
    @Published var isSaving = false
    @Published var isLoading = false
    @Published var notes: [MolNote] = [] //this molecule's notes (saved ones and ones waiting for the first save)
    @Published var savedMoleculeID: Int? = nil //nil  if it's never saved so save makes a new molecule
    @Published var isValidating = false
    @Published var problemAtomIDs: Set<Int> = [] //atoms the backend flagged, so the view can highlight them
    private var validationRun = 0 //bumps on every edit so an old result can't unlock save
    @Published var isDeleteMode = false //when on, tapping an atom or bond removes it
    @Published var showNotesPanel = false //the notes panel next to the sidebar (vision pro)

    // MARK: diagrams + electrons
    @Published var showElectrons = false //draw lone pairs / unpaired electrons on every atom
    @Published var diagramLayouts: DiagramLayouts? = nil //from the backend after a successful validate
    @Published var diagramKind: DiagramKind = .lewis
    @Published var showDiagramPanel = false //the "view diagram" panel (vision pro)
    @Published var panelOffsets: [String: SIMD3<Float>] = [:] //how far you've dragged each floating panel from its home spot (by panel name)
    //how far the floating molecule has morphed: 0 = normal 3D molecule, 1 = flat diagram
    @Published var diagramProgress: Double = 0

    // MARK: shapes (conformers)
    @Published var conformers: [Conformer] = [] //from the backend after a successful validate, most stable first
    @Published var selectedConformer = 0        //which one the molecule is showing right now
    private var shapeTask: Task<Void, Never>?
    private var morphTask: Task<Void, Never>?

    //database rows that currently hold this molecule's atoms/bonds so saving again can replace them instead of making a duplicate molecule
    private var savedAtomDBIDs: [Int] = []
    private var savedBondDBIDs: [Int] = []

    //TODO: replace with the logged-in user's id once login is built
    //user 1 has to exist in the user table for saving to work
    var currentUserID = 1

    //this is just for now bc my frontend isn't connected to my backend yet
    private var nextAtomID = 1
    private var nextBondID = 1

    //save only works after a successful validate
    var canSave: Bool {
        validationState == .valid && !isSaving
    }

    //structure info only makes sense for a molecule that passed validation
    var canSeeInfo: Bool {
        validationState == .valid
    }

    //diagrams need a validated molecule, since the backend works out the flat layout
    var canShowDiagram: Bool {
        validationState == .valid && diagramLayouts != nil
    }

    //while it's morphed (even partway) you can't edit, so taps and drags are ignored
    var isShowingDiagram: Bool {
        diagramProgress > 0
    }

    // MARK: - diagrams

    //play button: morph the molecule into the chosen diagram
    func playDiagram() {
        guard canShowDiagram else {
            statusMessage = "Validate your molecule first to see its diagrams"
            return
        }
        animateDiagram(to: 1)
        statusMessage = "Morphing into the \(diagramKind.rawValue.lowercased()) structure"
    }

    //back to the normal 3D molecule
    func morphBackTo3D() {
        animateDiagram(to: 0)
    }

    func toggleDiagramPanel() {
        showDiagramPanel.toggle()
        if !showDiagramPanel { morphBackTo3D() } //closing the panel puts the molecule back
    }

    //slides diagramProgress to the target over ~1.6s (eased so it starts and ends gently)
    private func animateDiagram(to target: Double, duration: Double = 1.6) {
        morphTask?.cancel()
        let start = diagramProgress
        guard start != target else { return }
        morphTask = Task {
            let startTime = Date()
            while !Task.isCancelled {
                let t = min(1, Date().timeIntervalSince(startTime) / (duration * abs(target - start)))
                let eased = t * t * (3 - 2 * t) //smoothstep
                diagramProgress = start + (target - start) * eased
                if t >= 1 { break }
                try? await Task.sleep(for: .milliseconds(16)) //~60 frames a second
            }
        }
    }

    //snap straight back to 3D with no animation (used when the molecule changes)
    private func resetDiagram() {
        morphTask?.cancel()
        morphTask = nil
        diagramProgress = 0
        diagramLayouts = nil
        shapeTask?.cancel()
        shapeTask = nil
        conformers = [] //the shapes were for the old molecule too
        selectedConformer = 0
    }

    // MARK: - shapes

    var hasMultipleShapes: Bool { conformers.count > 1 }

    //the diagram for the shape you're looking at: its own chair/boat drawing if it has one,
    //otherwise the molecule's normal flat diagram
    var currentDiagram: DiagramLayouts? {
        if conformers.indices.contains(selectedConformer), let own = conformers[selectedConformer].diagram {
            return own
        }
        return diagramLayouts
    }

    //switch to another stable shape: the atoms glide from where they are into the new shape
    func selectConformer(_ index: Int) {
        guard conformers.indices.contains(index) else { return }
        //if the diagram is up (vision pro), go back to 3D, glide into the new shape, then replay the diagram
        let replayDiagram = isShowingDiagram
        if replayDiagram {
            morphTask?.cancel()
            diagramProgress = 0
        }
        selectedConformer = index
        animateAtoms(to: geometryTargets(conformers[index].positions))
        statusMessage = "Showing \(conformers[index].label)"
        if replayDiagram {
            Task {
                try? await Task.sleep(for: .milliseconds(850)) //right after the 0.8s glide finishes
                guard selectedConformer == index else { return } //they picked another one in the meantime
                playDiagram()
            }
        }
    }

    func nextConformer() {
        guard hasMultipleShapes else { return }
        selectConformer((selectedConformer + 1) % conformers.count)
    }

    func previousConformer() {
        guard hasMultipleShapes else { return }
        selectConformer((selectedConformer - 1 + conformers.count) % conformers.count)
    }

    //slides every atom from where it is now to its target over ~0.8s (eased)
    private func animateAtoms(to targets: [Int: SIMD3<Float>], duration: Double = 0.8) {
        shapeTask?.cancel()
        let starts = Dictionary(uniqueKeysWithValues: atoms.map { ($0.idAtom, SIMD3($0.xcoord, $0.ycoord, $0.zcoord)) })
        shapeTask = Task {
            let startTime = Date()
            while !Task.isCancelled {
                let t = min(1, Date().timeIntervalSince(startTime) / duration)
                let eased = Float(t * t * (3 - 2 * t)) //smoothstep
                var frame: [Int: SIMD3<Float>] = [:]
                for (id, end) in targets {
                    guard let start = starts[id] else { continue }
                    frame[id] = start + (end - start) * eased
                }
                updateAtomPositions(frame)
                if t >= 1 { break }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    // MARK: - starting / opening a molecule

    //fresh empty builder
    func startNew() {
        atoms = []
        bonds = []
        notes = []
        moleculeName = ""
        savedMoleculeID = nil
        savedAtomDBIDs = []
        savedBondDBIDs = []
        selectedAtomIDsForBonding = []
        selectedBondType = nil
        isDeleteMode = false
        showNotesPanel = false
        showDiagramPanel = false
        panelOffsets = [:]
        nextAtomID = 1
        nextBondID = 1
        moleculeChanged()
        #if os(visionOS)
        statusMessage = "Tap an element to add it, then grab it to move it"
        #else
        statusMessage = "Drag an element into the space to start"
        #endif
    }

    //open a saved molecule from the home page
    func open(_ molecule: Molecule) async {
        startNew()
        moleculeName = molecule.name
        isLoading = true
        statusMessage = "Loading \(molecule.name)..."
        do {
            let loaded = try await MoleculeService.loadMolecule(id: molecule.idMolecule)
            //the database ids become the app ids, which is fine since they're unique
            atoms = loaded.atoms
            bonds = loaded.bonds
            notes = loaded.notes
            savedMoleculeID = molecule.idMolecule
            savedAtomDBIDs = loaded.atoms.map { $0.idAtom }
            savedBondDBIDs = loaded.bonds.map { $0.idBond }
            //new atoms/bonds need ids that don't clash with the loaded ones
            nextAtomID = (atoms.map { $0.idAtom }.max() ?? 0) + 1
            nextBondID = (bonds.map { $0.idBond }.max() ?? 0) + 1
            statusMessage = "Opened \(molecule.name)"
        } catch {
            statusMessage = "Couldn't open it: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - atoms
    
    //RDKit gives positions in ångströms (O-H ≈ 0.96), the scene is in meters
    #if os(visionOS)
    static let angstromToScene: Float = 0.1   //matches your ~10cm spacing in the room (the 3D view uses it for diagrams too)
    #else
    static let angstromToScene: Float = 0.06  //matches the phone spacing
    #endif

    //snap atoms into the real geometry, keeping the molecule roughly where the user built it
    private func applyGeometry(_ positions: [AtomPosition]) {
        updateAtomPositions(geometryTargets(positions))
    }

    //where each atom goes for a backend shape: scaled into the scene and centered where the molecule is now
    private func geometryTargets(_ positions: [AtomPosition]) -> [Int: SIMD3<Float>] {
        guard !atoms.isEmpty else { return [:] }
        let center = atoms.reduce(SIMD3<Float>(0, 0, 0)) {
            $0 + SIMD3($1.xcoord, $1.ycoord, $1.zcoord)
        } / Float(atoms.count)

        var newPositions: [Int: SIMD3<Float>] = [:]
        for p in positions {
            newPositions[p.atomId] = center + SIMD3(p.x, p.y, p.z) * Self.angstromToScene
        }
        return newPositions
    }

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

    //backup for when drag-and-drop isn't working: tap an element to add it near the middle
    //each new one is nudged over a bit so they don't land exactly on top of each other
    func addAtomNearCenter(element: String) {
        #if os(visionOS)
        let spacing: Float = 0.1   //10cm apart in the room
        #else
        let spacing: Float = 0.06  //closer together so they fit on a phone screen
        #endif
        let nudge = Float(atoms.count % 5 - 2) * spacing
        addAtom(element: element, at: (nudge, 0, 0))
    }

    //moving an atom doesn't change the chemistry, so it doesn't reset validation
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

    //used after a drag: saves the new spot for every atom that moved
    func updateAtomPositions(_ positions: [Int: SIMD3<Float>]) {
        for (atomID, position) in positions {
            updateAtomPosition(atomID: atomID, to: (position.x, position.y, position.z))
        }
    }

    //every atom connected to this one through bonds (including itself) = its molecule
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

    //tapping the same bond type again turns bond mode off
    func toggleBondType(_ type: BondType) {
        if selectedBondType == type {
            selectedBondType = nil
            statusMessage = "Bond mode off"
        } else {
            selectedBondType = type
            isDeleteMode = false //can't be bonding and deleting at the same time
            statusMessage = "\(type.rawValue.capitalized) bond: tap two atoms to connect them"
        }
        selectedAtomIDsForBonding = []
    }

    // MARK: - tapping (the views call these so delete mode and bond mode live in one place)

    func tapAtom(_ atomID: Int) {
        guard !isShowingDiagram else { return } //no editing while it's a diagram
        if isDeleteMode {
            deleteAtom(atomID)
        } else {
            selectAtomForBonding(atomID)
        }
    }

    //tapping a bond only does something in delete mode
    func tapBond(_ bondID: Int) {
        guard !isShowingDiagram else { return }
        if isDeleteMode {
            deleteBond(bondID)
        }
    }

    // MARK: - deleting

    func toggleDeleteMode() {
        isDeleteMode.toggle()
        if isDeleteMode {
            selectedBondType = nil //turn bond mode off so taps don't get confused
            selectedAtomIDsForBonding = []
            statusMessage = "Delete mode: tap an atom or bond to remove it"
        } else {
            statusMessage = "Delete mode off"
        }
    }

    //deleting an atom also deletes every bond attached to it (a bond can't point at nothing)
    func deleteAtom(_ atomID: Int) {
        guard let atom = atoms.first(where: { $0.idAtom == atomID }) else { return }
        let attached = bonds.filter { $0.idAtom1 == atomID || $0.idAtom2 == atomID }.count
        bonds.removeAll { $0.idAtom1 == atomID || $0.idAtom2 == atomID }
        atoms.removeAll { $0.idAtom == atomID }
        selectedAtomIDsForBonding.removeAll { $0 == atomID }
        moleculeChanged()
        switch attached {
        case 0: statusMessage = "Deleted \(atom.name)"
        case 1: statusMessage = "Deleted \(atom.name) and its bond"
        default: statusMessage = "Deleted \(atom.name) and its \(attached) bonds"
        }
    }

    func deleteBond(_ bondID: Int) {
        guard let bond = bonds.first(where: { $0.idBond == bondID }) else { return }
        bonds.removeAll { $0.idBond == bondID }
        moleculeChanged()
        statusMessage = "Deleted a \(bond.bondType.rawValue) bond"
    }

    func selectAtomForBonding(_ atomID: Int) {
        guard selectedBondType != nil else {
            statusMessage = "Pick a bond type on the right first"
            return
        }

        //tapping an atom you already picked unpicks it
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

        //don't allow two bonds between the same pair of atoms
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

    //any change to atoms or bonds means you have to validate again before saving
    private func moleculeChanged() {
        validationState = .notChecked
        problemAtomIDs = []
        validationRun += 1
        resetDiagram() //the old diagram is for the old molecule
    }

    func validate() {
        if atoms.isEmpty {
            validationState = .invalid("Add at least one atom first")
            statusMessage = "Add at least one atom first"
            return
        }

        isValidating = true
        statusMessage = "Checking your molecule..."
        let run = validationRun
        let atomsToCheck = atoms
        let bondsToCheck = bonds

        Task {
            do {
                let result = try await MoleculeService.validate(atoms: atomsToCheck, bonds: bondsToCheck)
                //if they edited while it was checking, this result is for an old molecule so ignore it
                guard run == validationRun else { isValidating = false; return }

                if result.valid {
                    diagramLayouts = result.diagram
                    validationState = .valid
                    conformers = result.conformers ?? []
                    selectedConformer = 0
                    if let positions = result.positions {
                        withAnimation { applyGeometry(positions) }
                        statusMessage = hasMultipleShapes
                            ? "Looks good! It can take \(conformers.count) shapes; this is the most stable one. See Shapes in the sidebar. You can save now."
                            : "Looks good! Snapped to the real shape. You can save now."
                    } else {
                        //the bond counts work, but RDKit couldn't find a real 3D shape
                        //(e.g. a ring of all double bonds: C=C=C wants to be straight, a ring forces it to bend)
                        statusMessage = "The bonds add up, but this molecule is too strained to exist in 3D, so it stayed as you drew it. You can still save it."
                    }
                } else {
                    problemAtomIDs = Set(result.errors.compactMap { $0.atomId })
                    let first = result.errors.first?.message ?? "Something's off with this molecule"
                    let extra = result.errors.count > 1 ? " (+\(result.errors.count - 1) more)" : ""
                    validationState = .invalid(first)
                    statusMessage = first + extra
                }
            } catch {
                validationState = .invalid("Couldn't validate")
                statusMessage = "Couldn't validate: \(error.localizedDescription)"
            }
            isValidating = false
        }
    }
    func save() {
        guard canSave else { return }
        let name = moleculeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            statusMessage = "Give your molecule a name first"
            return
        }

        isSaving = true
        statusMessage = "Saving..."
        // copies, so editing while it saves doesn't mix things up
        let atomsToSave = atoms
        let bondsToSave = bonds
        let pendingNotes = notes.filter { $0.idMoleculeNotes == nil }
        let isUpdate = savedMoleculeID != nil

        Task {
            do {
                let result = try await MoleculeService.save(
                    existingMoleculeID: savedMoleculeID,
                    name: name,
                    userID: currentUserID,
                    atoms: atomsToSave,
                    bonds: bondsToSave,
                    oldAtomDBIDs: savedAtomDBIDs,
                    oldBondDBIDs: savedBondDBIDs,
                    pendingNotes: pendingNotes
                )
                savedMoleculeID = result.moleculeID
                savedAtomDBIDs = result.atomDBIDs
                savedBondDBIDs = result.bondDBIDs
                // swap the waiting notes for their saved versions
                notes = notes.filter { $0.idMoleculeNotes != nil } + result.savedNotes
                statusMessage = isUpdate
                    ? "Updated \"\(name)\""
                    : "Saved \"\(name)\" to the database (molecule #\(result.moleculeID))"
            } catch {
                statusMessage = "Save failed: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }

    // MARK: - notes

    //if the molecule is already saved, the note goes straight to the database and if not it waits and gets saved together with the molecule
    func addNote(name: String, text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText: String? = trimmedText.isEmpty ? nil : trimmedText

        guard let moleculeID = savedMoleculeID else {
            notes.append(MolNote(idMoleculeNotes: nil, name: name, note: noteText, idMolecule: nil))
            statusMessage = "Note added. It'll be saved when you save the molecule."
            return
        }
        do {
            let saved = try await MoleculeService.addNote(name: name, text: noteText, moleculeID: moleculeID)
            notes.append(saved)
            statusMessage = "Note saved"
        } catch {
            statusMessage = "Couldn't save the note: \(error.localizedDescription)"
        }
    }

    func clear() {
        atoms = []
        bonds = []
        selectedAtomIDsForBonding = []
        isDeleteMode = false
        moleculeChanged()
        statusMessage = "Cleared. Add an element to start again"
    }
}
