//
//  Molecule3DView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI
import RealityKit

private class DragTracker {
    var startPosition: SIMD3<Float>? = nil
}

struct Molecule3DView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    private let dragTracker = DragTracker()

    var body: some View {
        RealityView { content in
            // initial setup, runs once
        } update: { content in
            content.entities.removeAll()

            for atom in viewModel.atoms {
                let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
                sphere.model?.materials = [SimpleMaterial(color: color(for: atom.name), isMetallic: false)]
                sphere.position = SIMD3(atom.xcoord, atom.ycoord, atom.zcoord)
                sphere.generateCollisionShapes(recursive: true)
                sphere.components.set(InputTargetComponent())
                sphere.name = "atom-\(atom.idAtom)"
                content.add(sphere)
            }

            for bond in viewModel.bonds {
                if let cylinder = bondCylinder(for: bond) {
                    content.add(cylinder)
                }
            }
        }
        .simultaneousGesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let atomID = extractAtomID(from: value.entity.name) {
                        viewModel.selectAtomForBonding(atomID)
                    }
                }
        )
        .simultaneousGesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    if dragTracker.startPosition == nil {
                        dragTracker.startPosition = value.entity.position
                    }
                    guard let start = dragTracker.startPosition else { return }
                    let translation = value.translation
                    value.entity.position.x = start.x + Float(translation.width) * 0.001
                    value.entity.position.y = start.y - Float(translation.height) * 0.001
                }
                .onEnded { value in
                    dragTracker.startPosition = nil
                    guard let atomID = extractAtomID(from: value.entity.name) else { return }
                    let newPosition = value.entity.position
                    viewModel.updateAtomPosition(atomID: atomID, to: (newPosition.x, newPosition.y, newPosition.z))
                }
        )
        .dropDestination(for: String.self) { droppedItems, location in
            guard let element = droppedItems.first else { return false }
            viewModel.addAtom(element: element, at: (0, 0, 0))
            return true
        }
    }

    private func extractAtomID(from entityName: String) -> Int? {
        let parts = entityName.split(separator: "-")
        guard parts.count == 2, let id = Int(parts[1]) else { return nil }
        return id
    }

    private func bondCylinder(for bond: Bond) -> ModelEntity? {
        guard let atom1 = viewModel.atoms.first(where: { $0.idAtom == bond.idAtom1 }),
              let atom2 = viewModel.atoms.first(where: { $0.idAtom == bond.idAtom2 }) else {
            return nil
        }
        let start = SIMD3(atom1.xcoord, atom1.ycoord, atom1.zcoord)
        let end = SIMD3(atom2.xcoord, atom2.ycoord, atom2.zcoord)
        let distance = simd_distance(start, end)

        let cylinder = ModelEntity(mesh: .generateCylinder(height: distance, radius: 0.01))
        cylinder.model?.materials = [SimpleMaterial(color: .gray, isMetallic: false)]
        cylinder.position = (start + end) / 2
        return cylinder
    }

    private func color(for element: String) -> SimpleMaterial.Color {
        switch element {
        case "H": return .white
        case "C": return .gray
        case "O": return .blue
        default: return .purple
        }
    }
}
