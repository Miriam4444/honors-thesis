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
}

struct Molecule3DView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    //true = floating in the room (vision pro immersive space)
    //false = inside a flat window (iPad / Mac) with drag-and-drop from the sidebar
    var isImmersive: Bool = false
    private let dragState = DragState()

    #if os(visionOS)
    @Environment(\.physicalMetrics) private var physicalMetrics //converts screen points to real meters
    #endif

    @State private var isDropTargeted = false //true while you're dragging an element over the space

    private let atomRadius: Float = 0.04

    var body: some View {
        if isImmersive {
            // nothing behind it, no drop zone: atoms just float in the room
            moleculeScene
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
        } update: { content in
            guard let root = content.entities.first(where: { $0.name == "root" }) else { return }
            //rebuild the scene from the view model every time it changes
            root.children.removeAll()

            for atom in viewModel.atoms {
                root.addChild(makeAtomEntity(for: atom))
            }

            for bond in viewModel.bonds {
                for line in 0..<lineCount(for: bond.bondType) {
                    let cylinder = ModelEntity(
                        mesh: .generateCylinder(height: 1, radius: 0.006), // stretched to the right length below
                        materials: [SimpleMaterial(color: .gray, isMetallic: false)]
                    )
                    cylinder.name = "bond-\(bond.idBond)-\(line)"
                    root.addChild(cylinder)
                }
            }
            layoutBonds(in: root)
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

    private func makeAtomEntity(for atom: Atom) -> ModelEntity {
        let isSelected = viewModel.selectedAtomIDsForBonding.contains(atom.idAtom)
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: atomRadius),
            materials: [SimpleMaterial(color: isSelected ? .yellow : color(for: atom.name), isMetallic: false)]
        )
        sphere.position = SIMD3(atom.xcoord, atom.ycoord, atom.zcoord)
        sphere.generateCollisionShapes(recursive: false)
        sphere.components.set(InputTargetComponent())
        #if os(visionOS)
        sphere.components.set(HoverEffectComponent()) // glows when you look at it
        #endif
        sphere.name = "atom-\(atom.idAtom)"
        return sphere
    }

    private func pointsToMeters(_ points: CGFloat) -> Float {
        #if os(visionOS)
        return Float(physicalMetrics.convert(points, to: .meters))
        #else
        return Float(points) * 0.001 //same scale the 2D drag uses
        #endif
    }

    // MARK: - gestures

    //tap an atom to pick it for bonding
    private var tapGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                if let atomID = extractAtomID(from: value.entity.name) {
                    viewModel.selectAtomForBonding(atomID)
                }
            }
    }

    //drag an atom to move it (or its whole molecule, depending on the toggle)
    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                guard let grabbedID = extractAtomID(from: value.entity.name),
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

    private func extractAtomID(from entityName: String) -> Int? {
        let parts = entityName.split(separator: "-")
        guard parts.count == 2, parts[0] == "atom", let id = Int(parts[1]) else { return nil }
        return id
    }

    // MARK: - bonds

    private func lineCount(for type: BondType) -> Int {
        switch type {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }

    //puts every bond cylinder between its two atoms using where the atom entities are right now
    private func layoutBonds(in root: Entity) {
        for bond in viewModel.bonds {
            guard let atom1 = root.findEntity(named: "atom-\(bond.idAtom1)"),
                  let atom2 = root.findEntity(named: "atom-\(bond.idAtom2)") else { continue }
            let count = lineCount(for: bond.bondType)
            for line in 0..<count {
                if let cylinder = root.findEntity(named: "bond-\(bond.idBond)-\(line)") {
                    place(cylinder, from: atom1.position, to: atom2.position, line: line, of: count)
                }
            }
        }
    }

    private func place(_ cylinder: Entity, from start: SIMD3<Float>, to end: SIMD3<Float>, line: Int, of count: Int) {
        let delta = end - start
        let distance = simd_length(delta)
        guard distance > 0.0001 else {
            cylinder.isEnabled = false // atoms on top of each other, nothing to draw
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

        //direction sideways to the bond, used to space out double/triple bond lines
        var side = simd_cross(direction, SIMD3(0, 0, 1))
        if simd_length(side) < 0.001 {
            side = simd_cross(direction, SIMD3(1, 0, 0))
        }
        side = simd_normalize(side)

        let spacing: Float = 0.018
        let offset = (Float(line) - Float(count - 1) / 2) * spacing
        cylinder.position = (start + end) / 2 + side * offset
        cylinder.scale = SIMD3(1, distance, 1) //the mesh is 1m tall, so this makes it exactly as long as the bond
    }

    private func color(for element: String) -> SimpleMaterial.Color {
        switch element {
        case "H": return .white
        case "C": return .darkGray
        case "O": return .red
        case "N": return .blue
        default: return .purple
        }
    }
}
