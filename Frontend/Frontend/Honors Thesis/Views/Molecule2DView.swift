//
//  Molecule2DView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/6/26.
//the same molecule as the 3D view but flat for phone/iPad/Mac screens.
//it basically just looks straight at the molecule from the front so x/y are kept and z is ignored.

import SwiftUI

//how molecule coordinates (meters) map onto the screen (points)
private struct ViewTransform {
    var scale: CGFloat          //points per meter
    var modelCenter: CGPoint    //the molecule spot (in meters) that sits in the middle of the view
    var screenCenter: CGPoint   //the middle of the view in points

    func toScreen(x: Float, y: Float) -> CGPoint {
        CGPoint(
            x: screenCenter.x + (CGFloat(x) - modelCenter.x) * scale,
            y: screenCenter.y - (CGFloat(y) - modelCenter.y) * scale //y goes up in 3D down on screen
        )
    }

    func toModel(_ point: CGPoint) -> (x: Float, y: Float) {
        (Float((point.x - screenCenter.x) / scale + modelCenter.x),
         Float(-(point.y - screenCenter.y) / scale + modelCenter.y))
    }
}

struct Molecule2DView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    //normal zoom matches the 3D window: 1 meter = 1000 points
    private let defaultScale: CGFloat = 1000
    private let atomDiameter: CGFloat = 40

    @State private var dragStartPositions: [Int: SIMD3<Float>] = [:] // where atoms were when a drag started
    @State private var dragTransform: ViewTransform? = nil // zoom is frozen while dragging so nothing jumps
    @State private var isDropTargeted = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let transform = dragTransform ?? fittedTransform(for: size)

            ZStack {
                // bonds go underneath the atoms
                Canvas { context, _ in
                    for bond in viewModel.bonds {
                        drawBond(bond, in: &context, transform: transform)
                    }
                }

                ForEach(viewModel.atoms, id: \.idAtom) { atom in
                    let point = transform.toScreen(x: atom.xcoord, y: atom.ycoord)
                    atomCircle(atom)
                        .position(point)
                        .gesture(dragGesture(for: atom, transform: transform))
                        .onTapGesture {
                            viewModel.selectAtomForBonding(atom.idAtom)
                        }
                        .allowsHitTesting(isInside(point, size: size))
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle()) //empty space counts as a drop zone too
            .clipped()
            //drop an element from the sidebar right where you let go
            .dropDestination(for: String.self) { droppedItems, location in
                guard let element = droppedItems.first else { return false }
                let spot = transform.toModel(location)
                viewModel.addAtom(element: element, at: (spot.x, spot.y, 0))
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isDropTargeted ? Color.green : Color.gray.opacity(0.3), lineWidth: isDropTargeted ? 4 : 1)
                    .allowsHitTesting(false)
            )
        }
    }

    // MARK: - zoom to fit

    //normally 1000 points per meter around (0,0) same as 3d window and if molecule doesn't fit (like one built big in the room on Vision Pro) zoom out and center on it so the whole thing is visible.
    private func fittedTransform(for size: CGSize) -> ViewTransform {
        let screenCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        let normal = ViewTransform(scale: defaultScale, modelCenter: .zero, screenCenter: screenCenter)

        guard !viewModel.atoms.isEmpty, size.width > atomDiameter * 2, size.height > atomDiameter * 2 else {
            return normal
        }
        let allFit = viewModel.atoms.allSatisfy { atom in
            isInside(normal.toScreen(x: atom.xcoord, y: atom.ycoord), size: size, margin: atomDiameter)
        }
        if allFit { return normal }

        let xs = viewModel.atoms.map { CGFloat($0.xcoord) }
        let ys = viewModel.atoms.map { CGFloat($0.ycoord) }
        let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        let usableWidth = size.width - atomDiameter * 2
        let usableHeight = size.height - atomDiameter * 2
        let scale = min(
            defaultScale,
            maxX > minX ? usableWidth / (maxX - minX) : defaultScale,
            maxY > minY ? usableHeight / (maxY - minY) : defaultScale
        )
        return ViewTransform(
            scale: scale,
            modelCenter: CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2),
            screenCenter: screenCenter
        )
    }

    private func isInside(_ point: CGPoint, size: CGSize, margin: CGFloat = 0) -> Bool {
        point.x >= margin && point.x <= size.width - margin &&
        point.y >= margin && point.y <= size.height - margin
    }

    // MARK: - atoms

    private func atomCircle(_ atom: Atom) -> some View {
        let isSelected = viewModel.selectedAtomIDsForBonding.contains(atom.idAtom)
        return Text(atom.name)
            .font(.headline)
            .foregroundStyle(labelColor(for: atom.name))
            .frame(width: atomDiameter, height: atomDiameter)
            .background(Circle().fill(isSelected ? Color.yellow : color(for: atom.name)))
            .overlay(Circle().stroke(Color.gray.opacity(0.6), lineWidth: 1)) // so white hydrogen shows up on white
            .contentShape(Circle())
    }

    //drag an atom (or its whole molecule, depending on the toggle)
    private func dragGesture(for atom: Atom, transform: ViewTransform) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if dragStartPositions.isEmpty {
                    dragTransform = transform // freeze the zoom until the drag ends
                    let movingIDs: Set<Int> = viewModel.moveMode == .molecule
                        ? viewModel.connectedAtomIDs(startingAt: atom.idAtom)
                        : [atom.idAtom]
                    for moving in viewModel.atoms where movingIDs.contains(moving.idAtom) {
                        dragStartPositions[moving.idAtom] = SIMD3(moving.xcoord, moving.ycoord, moving.zcoord)
                    }
                }
                let scale = dragTransform?.scale ?? transform.scale
                let dx = Float(value.translation.width / scale)
                let dy = Float(-value.translation.height / scale)
                var newPositions: [Int: SIMD3<Float>] = [:]
                for (id, start) in dragStartPositions {
                    newPositions[id] = SIMD3(start.x + dx, start.y + dy, start.z)
                }
                viewModel.updateAtomPositions(newPositions)
            }
            .onEnded { _ in
                dragStartPositions = [:]
                dragTransform = nil
            }
    }

    // MARK: - bonds

    //one line for single two for double three for triple side by side
    private func drawBond(_ bond: Bond, in context: inout GraphicsContext, transform: ViewTransform) {
        guard let atom1 = viewModel.atoms.first(where: { $0.idAtom == bond.idAtom1 }),
              let atom2 = viewModel.atoms.first(where: { $0.idAtom == bond.idAtom2 }) else { return }
        let start = transform.toScreen(x: atom1.xcoord, y: atom1.ycoord)
        let end = transform.toScreen(x: atom2.xcoord, y: atom2.ycoord)

        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0.5 else { return }
        //a direction sideways to the bond to space out double and triple lines
        let side = CGPoint(x: -dy / length, y: dx / length)

        let lineCount: Int
        switch bond.bondType {
        case .single: lineCount = 1
        case .double: lineCount = 2
        case .triple: lineCount = 3
        }
        let spacing: CGFloat = 6

        for line in 0..<lineCount {
            let offset = (CGFloat(line) - CGFloat(lineCount - 1) / 2) * spacing
            var path = Path()
            path.move(to: CGPoint(x: start.x + side.x * offset, y: start.y + side.y * offset))
            path.addLine(to: CGPoint(x: end.x + side.x * offset, y: end.y + side.y * offset))
            context.stroke(path, with: .color(.gray), lineWidth: 3)
        }
    }

    // MARK: - colors (same as the 3D view)

    private func color(for element: String) -> Color {
        switch element {
        case "H": return .white
        case "C": return Color(white: 0.3)
        case "O": return .red
        case "N": return .blue
        default: return .purple
        }
    }

    private func labelColor(for element: String) -> Color {
        element == "H" ? .black : .white
    }
}

#Preview {
    let viewModel = MoleculeBuilderVM()
    viewModel.addAtom(element: "O", at: (0, 0, 0))
    viewModel.addAtom(element: "H", at: (0.08, 0.06, 0))
    viewModel.addAtom(element: "H", at: (-0.08, 0.06, 0))
    return Molecule2DView(viewModel: viewModel)
}
