//
//  Molecule3DView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI
import RealityKit

//remembers where everything started when a drag begins
private class DragState {
    var startPositions: [Int: SIMD3<Float>] = [:] //atom id -> position when the drag started
    var panelStartOffset: SIMD3<Float>? //where a panel was when you grabbed its grab bar
}

//the flat plane the diagram gets drawn on. picked once when the morph starts so it faces you,
//and forgotten when the molecule goes back to 3D
private struct DiagramPlane {
    let right: SIMD3<Float>
    let up: SIMD3<Float>
    let normal: SIMD3<Float> //points from the diagram toward you

    var rotation: simd_quatf { simd_quatf(simd_float3x3(columns: (right, up, normal))) }
}

private class SceneState {
    weak var hud: Entity? //the head-following entity the panels hang off (vision pro)
    var diagramPlane: DiagramPlane?
    var paneMesh: MeshResource?
    var paneSize: SIMD2<Float>?
}

//meshes + materials are made once and reused, because the scene gets rebuilt every frame while it morphs
private enum SceneAssets {
    static let atomRadius: Float = 0.04
    static let atomMesh = MeshResource.generateSphere(radius: atomRadius)
    static let bondMesh = MeshResource.generateCylinder(height: 1, radius: 0.006) //stretched to the right length later
    static let dotRadius: Float = 0.006
    static let dotMesh = MeshResource.generateSphere(radius: dotRadius) //one electron
    //the black border: a slightly bigger black ball around each dot, drawn inside-out
    //(only its back half renders, so you see the colored dot with a black ring around it)
    static let dotOutlineMesh = MeshResource.generateSphere(radius: dotRadius * 1.4)
    static let dotOutlineMaterial: UnlitMaterial = {
        var material = UnlitMaterial(color: .black)
        material.faceCulling = .front
        return material
    }()
    static let bondMaterial = SimpleMaterial(color: .gray, isMetallic: false)
    static let labelMaterial = UnlitMaterial(color: .black) //black letters on the light pane
    //the "paper" the flat diagram sits on
    static let paneMaterial = SimpleMaterial(color: SimpleMaterial.Color(white: 0.96, alpha: 1), roughness: 0.9, isMetallic: false)

    private static var atomMaterials: [String: SimpleMaterial] = [:]
    private static var electronMaterials: [String: UnlitMaterial] = [:]
    private static var labelMeshes: [String: MeshResource] = [:]

    static func atomMaterial(for element: String, selected: Bool) -> SimpleMaterial {
        let key = selected ? "selected" : element
        if let cached = atomMaterials[key] { return cached }
        let color: SimpleMaterial.Color
        if selected {
            color = .yellow
        } else {
            let c = Elements.rgb(for: element) //same colors as the 2D view and sidebar
            color = SimpleMaterial.Color(red: CGFloat(c.red), green: CGFloat(c.green), blue: CGFloat(c.blue), alpha: 1)
        }
        let material = SimpleMaterial(color: color, isMetallic: false)
        atomMaterials[key] = material
        return material
    }

    //an electron dot is the same color as its atom (unlit = same brightness from every side)
    static func electronMaterial(for element: String) -> UnlitMaterial {
        if let cached = electronMaterials[element] { return cached }
        let c = Elements.rgb(for: element)
        let material = UnlitMaterial(color: SimpleMaterial.Color(red: CGFloat(c.red), green: CGFloat(c.green), blue: CGFloat(c.blue), alpha: 1))
        electronMaterials[element] = material
        return material
    }

    //3D text for "O", "OH", "NH₂"... (text meshes are slow to make, so each one is made once)
    static func labelMesh(for text: String) -> MeshResource {
        if let cached = labelMeshes[text] { return cached }
        let mesh = MeshResource.generateText(text, extrusionDepth: 0.002, font: .systemFont(ofSize: 0.035))
        labelMeshes[text] = mesh
        return mesh
    }
}

struct Molecule3DView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    //true = floating in the room (vision pro immersive space)
    //false = inside a flat window (iPad / Mac) with drag-and-drop from the sidebar
    var isImmersive: Bool = false
    @State private var dragState = DragState() //@State so it survives the view being recreated mid-drag

    #if os(visionOS)
    @Environment(\.physicalMetrics) private var physicalMetrics //converts screen points to real meters
    @State private var headFollower = HeadFollower() //moves the floating panels along with your head
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    #endif

    @State private var isDropTargeted = false //true while you're dragging an element over the space
    @State private var sceneState = SceneState()

    var body: some View {
        if isImmersive {
            // nothing behind it, no drop zone: atoms just float in the room
            moleculeScene
                #if os(visionOS)
                .task { await headFollower.start() }
                //while you're building, the floating sidebar is the only UI, so close the big window
                .onAppear { dismissWindow(id: MoleculeBuilderVM.mainWindowID) }
                //space closed (Done button, or the system closed it): bring the home window back
                .onDisappear {
                    headFollower.stop()
                    openWindow(id: MoleculeBuilderVM.mainWindowID)
                }
                #endif
        } else {
            windowedScene
        }
    }

    //the 3D molecule itself used by both versions
    private var moleculeScene: some View {
        RealityView { content in
            //everything goes inside one "root" entity so drags have a parent to measure against
            let root = Entity()
            root.name = "root"
            if isImmersive {
                //in the room, (0,0,0) is the floor under you
                root.position = SIMD3(0, 1.3, -0.8)
            }
            content.add(root)

            #if os(visionOS)
            //the floating panels (sidebar + notes) that follow your head around
            if isImmersive {
                let hud = makeHUD()
                sceneState.hud = hud
                content.add(hud)
                headFollower.follow(hud, in: content)
            }
            #endif
        } update: { content in
            #if os(visionOS)
            //notes + diagram panels only show when you open them from the sidebar
            let hud = content.entities.first(where: { $0.name == "hud" })
            hud?.findEntity(named: "panel-notes")?.isEnabled = viewModel.showNotesPanel
            hud?.findEntity(named: "panel-diagram")?.isEnabled = viewModel.showDiagramPanel
            for (name, home) in Self.panelHomes {
                guard let panel = hud?.findEntity(named: name) else { continue }
                //its home spot + however far you've dragged it
                panel.position = home + (viewModel.panelOffsets[name] ?? .zero)
            }
            #endif

            guard let root = content.entities.first(where: { $0.name == "root" }) else { return }
            //rebuild the scene from the view model every time it changes
            //(during the diagram morph that's every frame, which is why the meshes are cached)
            rebuildMolecule(in: root)
        }
        .simultaneousGesture(tapGesture)
        .simultaneousGesture(dragGesture)
    }

    //the flat-window version (iPad / Mac): same molecule, plus a drop zone for the sidebar
    private var windowedScene: some View {
        GeometryReader { geometry in
            moleculeScene
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                //drop an element from the left sidebar right where you let go
                .dropDestination(for: String.self) { droppedItems, location in
                    guard let element = droppedItems.first else { return false }
                    //the 3D origin is the middle of this view and y goes up in 3D but down on screen
                    let x = pointsToMeters(location.x - geometry.size.width / 2)
                    let y = -pointsToMeters(location.y - geometry.size.height / 2)
                    viewModel.addAtom(element: element, at: (x, y, 0))
                    return true
                } isTargeted: { targeted in
                    isDropTargeted = targeted
                }
                //green outline while you're holding an element over the space
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isDropTargeted ? Color.green : Color.gray.opacity(0.3), lineWidth: isDropTargeted ? 4 : 1)
                        .allowsHitTesting(false)
                )
        }
    }

    // MARK: - building the scene

    //draws the molecule somewhere between normal 3D (progress 0) and the flat diagram (progress 1)
    private func rebuildMolecule(in root: Entity) {
        root.children.removeAll()

        let progress = Float(viewModel.diagramProgress)
        let kind = viewModel.diagramKind
        let interactive = progress == 0 //no tapping/dragging while it's a diagram

        //pick the diagram's flat plane once, when the morph starts, so it faces wherever you're standing
        if progress == 0 {
            sceneState.diagramPlane = nil
        } else if sceneState.diagramPlane == nil {
            sceneState.diagramPlane = makeDiagramPlane(in: root)
        }
        let plane = sceneState.diagramPlane

        //where every atom is drawn right now: slide from its 3D spot toward its diagram spot
        let targets = (progress > 0 && plane != nil) ? diagramTargets(plane: plane!) : [:]
        var shown: [Int: SIMD3<Float>] = [:]
        for atom in viewModel.atoms {
            let start = SIMD3(atom.xcoord, atom.ycoord, atom.zcoord)
            if let end = targets[atom.idAtom] {
                shown[atom.idAtom] = start + (end - start) * progress
            } else {
                shown[atom.idAtom] = start
            }
        }

        let skeletalIDs = Set(viewModel.currentDiagram?.skeletal.map(\.atomId) ?? [])

        // atoms
        for atom in viewModel.atoms {
            guard let position = shown[atom.idAtom] else { continue }
            let scale = atomScale(atom, kind: kind, progress: progress, skeletalIDs: skeletalIDs)
            if scale > 0.001 {
                root.addChild(makeAtomEntity(for: atom, at: position, scale: scale, interactive: interactive))
            }
        }

        // bonds
        var thickness: [Int: Float] = [:]
        for bond in viewModel.bonds {
            thickness[bond.idBond] = bondThickness(bond, kind: kind, progress: progress, skeletalIDs: skeletalIDs)
            for line in 0..<lineCount(for: bond.bondType) {
                let cylinder = ModelEntity(mesh: SceneAssets.bondMesh, materials: [SceneAssets.bondMaterial])
                cylinder.name = "bond-\(bond.idBond)-\(line)"
                if interactive {
                    //a fatter invisible box around the bond so it's easy to tap (for delete mode)
                    //the box is 1m tall like the mesh, so it stretches with the bond too
                    cylinder.components.set(CollisionComponent(shapes: [.generateBox(size: [0.03, 1, 0.03])]))
                    cylinder.components.set(InputTargetComponent())
                    #if os(visionOS)
                    cylinder.components.set(HoverEffectComponent())
                    #endif
                }
                root.addChild(cylinder)
            }
        }
        //as labels fade in, bonds stop a little short of them so the lines don't run through the letters
        var trim: [Int: Float] = [:]
        if progress > 0.5 {
            let labelGap = 0.024 * min(1, (progress - 0.5) * 2)
            for atom in viewModel.atoms where hasLabel(atom, kind: kind, skeletalIDs: skeletalIDs) {
                trim[atom.idAtom] = labelGap
            }
        }
        //on the diagram pane, double/triple lines spread out flat along the pane (side by side as you look at it)
        //instead of possibly lining up one behind the other
        layoutBonds(in: root, positions: shown, thickness: thickness, trim: trim,
                    facing: plane?.normal ?? SIMD3(0, 0, 1))

        // the pane the diagram flattens onto (fades in as the molecule flattens)
        if progress > 0, let plane {
            addPane(to: root, targets: targets, progress: progress, plane: plane)
        }

        // electrons + labels
        addElectrons(to: root, shown: shown, progress: progress, kind: kind, plane: plane, skeletalIDs: skeletalIDs)
        if progress > 0.5, let plane {
            addLabels(to: root, shown: shown, progress: progress, kind: kind, plane: plane)
        }
    }

    private func makeAtomEntity(for atom: Atom, at position: SIMD3<Float>, scale: Float, interactive: Bool) -> ModelEntity {
        let isSelected = viewModel.selectedAtomIDsForBonding.contains(atom.idAtom)
        let sphere = ModelEntity(
            mesh: SceneAssets.atomMesh,
            materials: [SceneAssets.atomMaterial(for: atom.name, selected: isSelected)]
        )
        sphere.position = position
        sphere.scale = SIMD3(repeating: scale)
        if interactive {
            sphere.generateCollisionShapes(recursive: false)
            sphere.components.set(InputTargetComponent())
            #if os(visionOS)
            sphere.components.set(HoverEffectComponent()) // glows when you look at it
            #endif
        }
        sphere.name = "atom-\(atom.idAtom)"
        return sphere
    }

    // MARK: - diagram morph

    //which way is "toward you"? on vision pro that's where your head is; in a window it's the screen
    private func makeDiagramPlane(in root: Entity) -> DiagramPlane {
        let center = moleculeCenter()
        var toViewer = SIMD3<Float>(0, 0, 1)
        #if os(visionOS)
        if isImmersive, let head = headFollower.lastHeadPosition {
            toViewer = root.convert(position: head, from: nil) - center
        }
        #endif
        toViewer.y = 0 //keep the diagram standing up straight, even if you're looking down at it
        let normal = simd_length(toViewer) > 0.001 ? simd_normalize(toViewer) : SIMD3<Float>(0, 0, 1)
        let up = SIMD3<Float>(0, 1, 0)
        let right = simd_normalize(simd_cross(up, normal))
        return DiagramPlane(right: right, up: up, normal: normal)
    }

    private func moleculeCenter() -> SIMD3<Float> {
        guard !viewModel.atoms.isEmpty else { return .zero }
        let sum = viewModel.atoms.reduce(SIMD3<Float>(0, 0, 0)) { $0 + SIMD3($1.xcoord, $1.ycoord, $1.zcoord) }
        return sum / Float(viewModel.atoms.count)
    }

    //where each atom ends up in the flat diagram (same spot in the room as the 3D molecule's center)
    private func diagramTargets(plane: DiagramPlane) -> [Int: SIMD3<Float>] {
        guard let layouts = viewModel.currentDiagram else { return [:] } //this shape's chair/boat drawing, or the flat one
        let center = moleculeCenter()
        let scale = MoleculeBuilderVM.angstromToScene
        let points = viewModel.diagramKind == .lewis ? layouts.lewis : layouts.skeletal

        var targets: [Int: SIMD3<Float>] = [:]
        for point in points {
            targets[point.atomId] = center + (plane.right * point.x + plane.up * point.y) * scale
        }
        //bond-line drawings leave out the H's, so they slide into the atom they're attached to and shrink away
        for atom in viewModel.atoms where targets[atom.idAtom] == nil {
            let neighbor = neighborIDs(of: atom.idAtom).first { targets[$0] != nil }
            targets[atom.idAtom] = neighbor.flatMap { targets[$0] } ?? center
        }
        return targets
    }

    private func neighborIDs(of atomID: Int) -> [Int] {
        viewModel.bonds.compactMap { bond in
            if bond.idAtom1 == atomID { return bond.idAtom2 }
            if bond.idAtom2 == atomID { return bond.idAtom1 }
            return nil
        }
    }

    //how big each atom's ball is during the morph (1 = normal size, 0 = gone).
    //in both diagrams the balls shrink away: Lewis replaces them with element symbols,
    //bond-line turns carbons into plain corners, drops the H's, and labels everything else ("OH")
    private func atomScale(_ atom: Atom, kind: DiagramKind, progress: Float, skeletalIDs: Set<Int>) -> Float {
        //a carbon in a straight line (C=C=C, C≡C) has no corner in a bond-line drawing,
        //so it keeps a small dot instead of vanishing (like in textbooks)
        if kind == .bondLine, isStraightCarbon(atom.idAtom) {
            return 1 - 0.8 * progress
        }
        return 1 - progress
    }

    private func isStraightCarbon(_ atomID: Int) -> Bool {
        viewModel.currentDiagram?.skeletal.first(where: { $0.atomId == atomID })?.straight == true
    }

    //which atoms get a written label in the finished diagram
    private func hasLabel(_ atom: Atom, kind: DiagramKind, skeletalIDs: Set<Int>) -> Bool {
        switch kind {
        case .lewis: return true
        case .bondLine: return atom.name != "C" && skeletalIDs.contains(atom.idAtom)
        }
    }

    //bond thickness during the morph (bonds to disappearing H's thin out to nothing in bond-line)
    private func bondThickness(_ bond: Bond, kind: DiagramKind, progress: Float, skeletalIDs: Set<Int>) -> Float {
        guard progress > 0 else { return 1 }
        var thickness: Float = 1
        //chair/boat drawings: the bonds closest to you get bolder as it flattens, like the textbook drawings
        if let closeness = viewModel.currentDiagram?.closeness(of: bond, kind: kind) {
            //(1 at the start of the morph -> 0.8 for the farthest ring bond up to 1.8 for the closest at the end)
            thickness *= 1 + (-0.2 + 1.0 * closeness * closeness) * progress
        }
        if kind == .bondLine {
            let keeps = skeletalIDs.contains(bond.idAtom1) && skeletalIDs.contains(bond.idAtom2)
            if !keeps { thickness *= 1 - progress } //bonds to hidden H's thin out to nothing
        }
        return thickness
    }

    //a light board behind the diagram, sized to fit it with some margin, like the diagram is drawn on paper
    private func addPane(to root: Entity, targets: [Int: SIMD3<Float>], progress: Float, plane: DiagramPlane) {
        guard !targets.isEmpty else { return }
        let center = moleculeCenter()
        //how far the diagram reaches left/right and up/down, measured along the pane
        let xs = targets.values.map { simd_dot($0 - center, plane.right) }
        let ys = targets.values.map { simd_dot($0 - center, plane.up) }
        let margin: Float = 0.07 //room for labels + lone pairs around the edge
        let width = (xs.max()! - xs.min()!) + margin * 2
        let height = (ys.max()! - ys.min()!) + margin * 2

        //the board's mesh only changes when the diagram's size does
        let size = SIMD2(width, height)
        if sceneState.paneSize != size || sceneState.paneMesh == nil {
            sceneState.paneMesh = MeshResource.generateBox(width: width, height: height, depth: 0.006, cornerRadius: 0.012)
            sceneState.paneSize = size
        }
        guard let mesh = sceneState.paneMesh else { return }

        let pane = ModelEntity(mesh: mesh, materials: [SceneAssets.paneMaterial])
        let middle = center
            + plane.right * ((xs.max()! + xs.min()!) / 2)
            + plane.up * ((ys.max()! + ys.min()!) / 2)
        pane.position = middle - plane.normal * 0.016 //just behind the diagram so the dots and bonds sit on top
        pane.orientation = plane.rotation
        pane.components.set(OpacityComponent(opacity: min(1, progress * 1.5))) //fades in a bit ahead of the morph
        root.addChild(pane)
    }

    //element symbols that fade in over the second half of the morph
    private func addLabels(to root: Entity, shown: [Int: SIMD3<Float>], progress: Float, kind: DiagramKind, plane: DiagramPlane) {
        let grow = min(1, (progress - 0.5) * 2) //0 at the halfway point, 1 at the end
        let skeletal = Dictionary(uniqueKeysWithValues: (viewModel.currentDiagram?.skeletal ?? []).map { ($0.atomId, $0) })

        for atom in viewModel.atoms {
            guard let position = shown[atom.idAtom] else { continue }
            //carbons and hydrogens aren't written in bond-line drawings
            guard hasLabel(atom, kind: kind, skeletalIDs: Set(skeletal.keys)) else { continue }
            let text: String
            switch kind {
            case .lewis:
                text = atom.name
            case .bondLine:
                text = atom.name + hydrogenSuffix(skeletal[atom.idAtom]?.hydrogens ?? 0)
            }
            let mesh = SceneAssets.labelMesh(for: text)
            let label = ModelEntity(mesh: mesh, materials: [SceneAssets.labelMaterial])
            //text meshes start at their bottom-left corner, so shift it to be centered on the atom
            label.position = -mesh.bounds.center
            let holder = Entity()
            holder.position = position + plane.normal * 0.005 //just in front so it isn't inside a bond
            holder.orientation = plane.rotation
            holder.scale = SIMD3(repeating: grow)
            holder.addChild(label)
            root.addChild(holder)
        }
    }

    private func hydrogenSuffix(_ count: Int) -> String {
        switch count {
        case 0: return ""
        case 1: return "H"
        default:
            let subscripts = ["₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉"]
            return "H" + String(count).compactMap { Int(String($0)) }.map { subscripts[$0] }.joined()
        }
    }

    // MARK: - electrons

    private func addElectrons(to root: Entity, shown: [Int: SIMD3<Float>], progress: Float, kind: DiagramKind, plane: DiagramPlane?, skeletalIDs: Set<Int>) {
        //Lewis structures always show their lone pairs (they fade in over the second half of the morph).
        //otherwise dots only show when "show electrons" is on, and they fade out for bond-line
        let flat: Bool
        let dotScale: Float
        if kind == .lewis && progress > 0.5 && plane != nil {
            flat = true
            dotScale = min(1, (progress - 0.5) * 2)
        } else if viewModel.showElectrons && (progress == 0 || kind == .lewis) {
            flat = false
            dotScale = 1
        } else if viewModel.showElectrons && kind == .bondLine {
            flat = false
            dotScale = 1 - progress
        } else {
            return
        }
        guard dotScale > 0.001 else { return }

        //pairs spread out sideways from where you're looking
        let toViewer = plane?.normal ?? viewerDirection(in: root)
        let candidates = flat && plane != nil
            ? ElectronLayout.circleDirections(right: plane!.right, up: plane!.up)
            : ElectronLayout.sphereDirections

        for atom in viewModel.atoms {
            guard let center = shown[atom.idAtom],
                  let electrons = ElectronLayout.count(for: atom, bonds: viewModel.bonds),
                  !electrons.isEmpty else { continue }
            if kind == .bondLine && progress > 0 && !skeletalIDs.contains(atom.idAtom) { continue }

            var bondDirections = neighborIDs(of: atom.idAtom).compactMap { shown[$0].map { $0 - center } }
            if flat, let plane {
                //in the flat diagram, only the in-plane part of each bond direction matters
                bondDirections = bondDirections.map { $0 - plane.normal * simd_dot($0, plane.normal) }
            }
            let ballRadius = SceneAssets.atomRadius * atomScale(atom, kind: kind, progress: progress, skeletalIDs: skeletalIDs)
            let dots = ElectronLayout.dotPositions(
                center: center,
                bondDirections: bondDirections,
                electrons: electrons,
                distance: max(ballRadius + 0.015, 0.032), //outside the ball, or around the letter in a Lewis drawing
                pairSpacing: 0.019, //wide enough that the two outlined dots of a pair don't overlap
                candidates: candidates,
                sideways: toViewer
            )
            for spot in dots {
                let dot = ModelEntity(mesh: SceneAssets.dotMesh, materials: [SceneAssets.electronMaterial(for: atom.name)])
                dot.addChild(ModelEntity(mesh: SceneAssets.dotOutlineMesh, materials: [SceneAssets.dotOutlineMaterial]))
                dot.position = spot
                dot.scale = SIMD3(repeating: dotScale)
                root.addChild(dot)
            }
        }
    }

    //direction from the molecule toward you (used so electron pairs look like ":" from where you stand)
    private func viewerDirection(in root: Entity) -> SIMD3<Float> {
        #if os(visionOS)
        if isImmersive, let head = headFollower.lastHeadPosition {
            let toViewer = root.convert(position: head, from: nil) - moleculeCenter()
            if simd_length(toViewer) > 0.001 { return simd_normalize(toViewer) }
        }
        #endif
        return SIMD3(0, 0, 1)
    }

    private func pointsToMeters(_ points: CGFloat) -> Float {
        #if os(visionOS)
        return Float(physicalMetrics.convert(points, to: .meters))
        #else
        return Float(points) * 0.001 //same scale the 2D drag uses
        #endif
    }

    // MARK: - gestures

    //tap an atom to pick it for bonding, or in delete mode tap an atom/bond to remove it
    private var tapGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                if let atomID = extractAtomID(from: value.entity.name) {
                    viewModel.tapAtom(atomID)
                } else if let bondID = extractBondID(from: value.entity.name) {
                    viewModel.tapBond(bondID)
                }
            }
    }

    //drag an atom to move it (or its whole molecule, depending on the toggle)
    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard !viewModel.isShowingDiagram, //no moving atoms while it's a diagram
                      let grabbedID = extractAtomID(from: value.entity.name),
                      let root = value.entity.parent else { return }

                // first moment of the drag: figure out which atoms are moving and where they started
                if dragState.startPositions.isEmpty {
                    let movingIDs: Set<Int> = viewModel.moveMode == .molecule
                        ? viewModel.connectedAtomIDs(startingAt: grabbedID)
                        : [grabbedID]
                    for id in movingIDs {
                        if let entity = root.findEntity(named: "atom-\(id)") {
                            dragState.startPositions[id] = entity.position
                        }
                    }
                }

                //how far the drag has moved in 3D meters
                let delta: SIMD3<Float>
                #if os(visionOS)
                //on vision pro the drag has a real 3D location so things follow your hand
                let now = value.convert(value.location3D, from: .local, to: root)
                let start = value.convert(value.startLocation3D, from: .local, to: root)
                delta = now - start
                #else
                //on iPhone/iPad/Mac the drag is 2D so move in x/y only
                delta = SIMD3(Float(value.translation.width) * 0.001,
                              -Float(value.translation.height) * 0.001,
                              0)
                #endif

                for (id, startPosition) in dragState.startPositions {
                    root.findEntity(named: "atom-\(id)")?.position = startPosition + delta
                }
                layoutBonds(in: root) //bonds stretch along while you drag
            }
            .onEnded { value in
                guard let root = value.entity.parent else {
                    dragState.startPositions = [:]
                    return
                }
                //save where everything ended up
                var finalPositions: [Int: SIMD3<Float>] = [:]
                for id in dragState.startPositions.keys {
                    if let entity = root.findEntity(named: "atom-\(id)") {
                        finalPositions[id] = entity.position
                    }
                }
                dragState.startPositions = [:]
                viewModel.updateAtomPositions(finalPositions)
            }
    }

    #if os(visionOS)
    //called by a panel's GrabBar while you drag it. it still follows your head, just from the new spot
    //roomDelta = how far your hand moved since you grabbed the bar, in room directions (meters)
    private func movePanel(named name: String, by roomDelta: SIMD3<Float>) {
        guard let hud = sceneState.hud else { return }
        if dragState.panelStartOffset == nil {
            dragState.panelStartOffset = viewModel.panelOffsets[name] ?? .zero
        }
        //turn the room direction into the hud's directions (so "left" means your left even if you've turned)
        let localDelta = hud.convert(direction: roomDelta, from: nil)
        viewModel.panelOffsets[name] = (dragState.panelStartOffset ?? .zero) + localDelta
    }
    #endif

    private func extractAtomID(from entityName: String) -> Int? {
        let parts = entityName.split(separator: "-")
        guard parts.count == 2, parts[0] == "atom", let id = Int(parts[1]) else { return nil }
        return id
    }

    //bond entities are named "bond-<bond id>-<which line>"
    private func extractBondID(from entityName: String) -> Int? {
        let parts = entityName.split(separator: "-")
        guard parts.count == 3, parts[0] == "bond", let id = Int(parts[1]) else { return nil }
        return id
    }

    // MARK: - floating panels (vision pro)

    #if os(visionOS)
    //where each draggable panel sits before you drag it anywhere (meters from your eyes)
    private static let panelHomes: [String: SIMD3<Float>] = [
        "panel-sidebar": SIMD3(-0.42, -0.05, -0.9), //left
        "panel-diagram": SIMD3(0, -0.25, -0.6),     //low and close, in front of the molecule's diagram pane
    ]

    //a panel you can drag: the SwiftUI view with a GrabBar on top (on top so it's always easy to reach,
    //even when the panel is low in your view). pinch + drag the bar to move the whole panel
    private func makeDraggablePanel(named name: String, view: some View, orientation: simd_quatf) -> Entity {
        let panel = Entity()
        panel.name = name
        panel.components.set(ViewAttachmentComponent(rootView:
            VStack(spacing: 10) {
                GrabBar(
                    onDrag: { roomDelta in movePanel(named: name, by: roomDelta) },
                    onEnd: { dragState.panelStartOffset = nil }
                )
                view
            }
        ))

        panel.position = (Self.panelHomes[name] ?? .zero) + (viewModel.panelOffsets[name] ?? .zero)
        panel.orientation = orientation
        return panel
    }

    //one invisible "hud" entity that follows your head, with the panels hung off it.
    //positions are in meters relative to your eyes: -z is straight ahead, -x is left, -y is down
    private func makeHUD() -> Entity {
        let hud = Entity()
        hud.name = "hud"
        hud.position = SIMD3(0, 1.4, 0) //about eye height, used until head tracking kicks in

        //left: everything (name/validate/save, delete + move toggle, atoms, bonds, notes button)
        let sidebar = makeDraggablePanel(
            named: "panel-sidebar",
            view: BuilderSidebarView(
                viewModel: viewModel,
                showsMoleculeControls: true,
                onDone: { Task { await dismissImmersiveSpace() } }, //onDisappear above reopens the home window
                onDiagramTapped: { viewModel.toggleDiagramPanel() }
            ) {
                viewModel.showNotesPanel.toggle()
            }
            .glassBackgroundEffect(),
            orientation: simd_quatf(angle: 0.4, axis: [0, 1, 0]) //turned to face you
        )
        hud.addChild(sidebar)

        //right: notes, hidden until you tap the notes button
        let notes = Entity()
        notes.name = "panel-notes"
        notes.components.set(ViewAttachmentComponent(rootView:
            NotesPanelView(viewModel: viewModel)
                .glassBackgroundEffect()
        ))
        notes.position = SIMD3(0.42, -0.02, -0.9)
        notes.orientation = simd_quatf(angle: -0.4, axis: [0, 1, 0])
        notes.isEnabled = viewModel.showNotesPanel
        hud.addChild(notes)

        //bottom middle: view diagram (Lewis / bond-line toggle + play button), hidden until you open it
        //it's closer to you (60cm) than the molecule, so the diagram's pane never ends up in front of it
        let diagram = makeDraggablePanel(
            named: "panel-diagram",
            view: DiagramPanelView(viewModel: viewModel)
                .glassBackgroundEffect(),
            orientation: simd_quatf(angle: -0.3, axis: [1, 0, 0]) //tilted up toward you
        )
        diagram.isEnabled = viewModel.showDiagramPanel
        hud.addChild(diagram)

        return hud
    }
    #endif

    // MARK: - bonds

    private func lineCount(for type: BondType) -> Int {
        switch type {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }

    //puts every bond cylinder between its two atoms.
    //positions = where each atom is drawn (if left out, uses where the atom entities are right now, like during a drag)
    //thickness = 1 normally, smaller while a bond fades out in the bond-line morph
    //trim = how much to cut off each end (by atom id), so bonds don't overlap a diagram label
    //facing = direction toward the viewer, so double/triple lines spread out side by side instead of lining up behind each other
    private func layoutBonds(in root: Entity, positions: [Int: SIMD3<Float>]? = nil, thickness: [Int: Float] = [:], trim: [Int: Float] = [:],
                             facing: SIMD3<Float> = SIMD3(0, 0, 1), lineSpacing: Float = 0.018) {
        for bond in viewModel.bonds {
            let fullStart = positions?[bond.idAtom1] ?? root.findEntity(named: "atom-\(bond.idAtom1)")?.position
            let fullEnd = positions?[bond.idAtom2] ?? root.findEntity(named: "atom-\(bond.idAtom2)")?.position
            guard let fullStart, let fullEnd else { continue }
            var start = fullStart
            var end = fullEnd
            let length = simd_length(fullEnd - fullStart)
            let cut1 = trim[bond.idAtom1] ?? 0
            let cut2 = trim[bond.idAtom2] ?? 0
            if length > cut1 + cut2 + 0.005 {
                let direction = (fullEnd - fullStart) / length
                start += direction * cut1
                end -= direction * cut2
            }
            let count = lineCount(for: bond.bondType)
            for line in 0..<count {
                if let cylinder = root.findEntity(named: "bond-\(bond.idBond)-\(line)") {
                    place(cylinder, from: start, to: end, line: line, of: count, thickness: thickness[bond.idBond] ?? 1,
                          facing: facing, spacing: lineSpacing)
                }
            }
        }
    }

    private func place(_ cylinder: Entity, from start: SIMD3<Float>, to end: SIMD3<Float>, line: Int, of count: Int, thickness: Float = 1,
                       facing: SIMD3<Float> = SIMD3(0, 0, 1), spacing: Float = 0.018) {
        let delta = end - start
        let distance = simd_length(delta)
        guard distance > 0.0001, thickness > 0.001 else {
            cylinder.isEnabled = false // atoms on top of each other (or the bond faded out), nothing to draw
            return
        }
        cylinder.isEnabled = true
        let direction = delta / distance
        let up = SIMD3<Float>(0, 1, 0)
        if simd_dot(up, direction) < -0.9999 {
            cylinder.orientation = simd_quatf(angle: .pi, axis: SIMD3(1, 0, 0))
        } else {
            cylinder.orientation = simd_quatf(from: up, to: direction)
        }

        //direction sideways to the bond (as seen from `facing`), used to space out double/triple bond lines.
        //it's perpendicular to both the bond and the direction toward you, so the lines sit side by side
        var side = simd_cross(direction, facing)
        if simd_length(side) < 0.001 {
            side = simd_cross(direction, SIMD3(0, 1, 0)) //bond points straight at you: any sideways works
        }
        if simd_length(side) < 0.001 {
            side = simd_cross(direction, SIMD3(1, 0, 0))
        }
        side = simd_normalize(side)

        let offset = (Float(line) - Float(count - 1) / 2) * spacing
        cylinder.position = (start + end) / 2 + side * offset
        //the mesh is 1m tall, so this makes it exactly as long as the bond
        cylinder.scale = SIMD3(thickness, distance, thickness)
    }
}
