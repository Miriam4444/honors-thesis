//
//  DiagramView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/27/26.
//the "Diagram" tab on iPhone / iPad / Mac. pick Lewis or bond-line and your 2D drawing
//slides into that diagram (and you can hit replay to watch it again).
//the flat layouts come from the backend (RDKit) after a successful validate.

import SwiftUI

struct DiagramView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    @State private var morphStart = Date() //when the current morph started playing
    private let duration: Double = 1.4

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Diagram", selection: $viewModel.diagramKind) {
                    ForEach(DiagramKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 240)

                Button {
                    morphStart = Date() //replay
                } label: {
                    Label("Replay", systemImage: "play.fill")
                }
                .disabled(!viewModel.canShowDiagram)
            }


            if let layouts = viewModel.currentDiagram, viewModel.canShowDiagram {
                //redraws every frame; progress goes 0 -> 1 over `duration` seconds after morphStart
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(morphStart)
                    let t = min(1, max(0, elapsed / duration))
                    DiagramDrawing(
                        atoms: viewModel.atoms,
                        bonds: viewModel.bonds,
                        layouts: layouts,
                        kind: viewModel.diagramKind,
                        progress: t * t * (3 - 2 * t) //smoothstep: starts and ends gently
                    )
                }
            } else {
                //diagrams come from the backend, which needs a molecule that passed validation
                ContentUnavailableView(
                    "No diagram yet",
                    systemImage: "square.on.circle",
                    description: Text("Validate your molecule first, then come back to this tab.")
                )
            }
        }
        .onAppear { morphStart = Date() }                          //play when you open the tab
        .onChange(of: viewModel.diagramKind) { morphStart = Date() } //and when you switch Lewis <-> bond-line
        .onChange(of: viewModel.selectedConformer) {
            //replay once the molecule has finished gliding into the new shape
            Task {
                try? await Task.sleep(for: .milliseconds(850))
                morphStart = Date()
            }
        }
    }
}

//draws one frame of the morph: progress 0 = your 2D drawing, 1 = the finished diagram
private struct DiagramDrawing: View {
    let atoms: [Atom]
    let bonds: [Bond]
    let layouts: DiagramLayouts
    let kind: DiagramKind
    let progress: Double

    private let atomRadius: CGFloat = 20 //same size as the 2D view's atoms

    var body: some View {
        Canvas { context, size in
            let p = CGFloat(progress)
            let start = fitDrawing(in: size)
            let end = fitDiagram(in: size)
            let skeletal = Dictionary(uniqueKeysWithValues: layouts.skeletal.map { ($0.atomId, $0) })

            //where each atom is drawn this frame
            var shown: [Int: CGPoint] = [:]
            for atom in atoms {
                guard let a = start[atom.idAtom], let b = end[atom.idAtom] else { continue }
                shown[atom.idAtom] = CGPoint(x: a.x + (b.x - a.x) * p, y: a.y + (b.y - a.y) * p)
            }

            // bonds (bonds to hydrogens fade out in bond-line)
            for bond in bonds {
                guard let a = shown[bond.idAtom1], let b = shown[bond.idAtom2] else { continue }
                var opacity: CGFloat = 1
                if kind == .bondLine && !(skeletal[bond.idAtom1] != nil && skeletal[bond.idAtom2] != nil) {
                    opacity = 1 - p
                }
                //chair/boat drawings: the closest bonds get bolder as it flattens (the textbook bold front edge)
                var width: CGFloat = 3
                if let closeness = layouts.closeness(of: bond, kind: kind) {
                    width = 3 * (1 - p) + (2 + 3 * CGFloat(closeness * closeness)) * p //2pt at the back, 5pt at the front
                }
                drawBond(from: a, to: b, type: bond.bondType, opacity: opacity, width: width, in: &context)
            }

            // atoms: the colored balls shrink away and the diagram's labels fade in
            let labelOpacity = max(0, (p - 0.5) * 2) //0 until halfway, 1 at the end

            //bond-line: a carbon in a straight line (C=C=C, C≡C) has no corner, so it gets a dot
            //(like in textbooks) instead of vanishing
            if kind == .bondLine && labelOpacity > 0 {
                var dotContext = context
                dotContext.opacity = Double(labelOpacity)
                for point in layouts.skeletal where point.straight == true {
                    guard let spot = shown[point.atomId] else { continue }
                    let r: CGFloat = 5
                    dotContext.fill(Path(ellipseIn: CGRect(x: spot.x - r, y: spot.y - r, width: r * 2, height: r * 2)),
                                    with: .color(.gray))
                }
            }
            for atom in atoms {
                guard let point = shown[atom.idAtom] else { continue }

                let ballRadius = atomRadius * (1 - p)
                if ballRadius > 0.5 {
                    let ball = Path(ellipseIn: CGRect(x: point.x - ballRadius, y: point.y - ballRadius, width: ballRadius * 2, height: ballRadius * 2))
                    context.fill(ball, with: .color(Elements.color(for: atom.name)))
                    context.stroke(ball, with: .color(.gray.opacity(0.6)), lineWidth: 1)
                    //the ball's own symbol fades out with it
                    var faded = context
                    faded.opacity = Double(1 - p)
                    faded.draw(Text(atom.name).font(.headline).foregroundStyle(Elements.labelColor(for: atom.name)), at: point)
                }

                //the diagram's label: every atom in Lewis, only non-carbon atoms (with their H's) in bond-line
                let label: String?
                switch kind {
                case .lewis:
                    label = atom.name
                case .bondLine:
                    if atom.name != "C", let skeletalPoint = skeletal[atom.idAtom] {
                        label = atom.name + hydrogenSuffix(skeletalPoint.hydrogens ?? 0)
                    } else {
                        label = nil
                    }
                }
                if let label, labelOpacity > 0 {
                    var labelContext = context
                    labelContext.opacity = Double(labelOpacity)
                    //a patch of background behind the letters so bond lines don't run through them
                    let patch = Path(ellipseIn: CGRect(x: point.x - 13, y: point.y - 13, width: 26, height: 26))
                    labelContext.fill(patch, with: .style(.background))
                    labelContext.draw(Text(label).font(.title3.bold()).foregroundStyle(.primary), at: point)
                }
            }

            // Lewis structures show every atom's lone pairs + unpaired electrons
            if kind == .lewis && labelOpacity > 0 {
                var dotContext = context
                dotContext.opacity = Double(labelOpacity)
                drawElectrons(shown: shown, in: &dotContext)
            }
        }
    }

    // MARK: - fitting both layouts into the view

    //your 2D drawing (same view as the 2D tab: x right, y up, z ignored)
    private func fitDrawing(in size: CGSize) -> [Int: CGPoint] {
        let points = atoms.map { (id: $0.idAtom, x: CGFloat($0.xcoord), y: CGFloat($0.ycoord)) }
        return fit(points, in: size, maxScale: 1000) //1000 points per meter, like the 2D view
    }

    //the backend's flat diagram; anything it leaves out (H's in bond-line) sits on the atom it's bonded to
    private func fitDiagram(in size: CGSize) -> [Int: CGPoint] {
        let layout = kind == .lewis ? layouts.lewis : layouts.skeletal
        var fitted = fit(layout.map { (id: $0.atomId, x: CGFloat($0.x), y: CGFloat($0.y)) }, in: size, maxScale: 60)
        for atom in atoms where fitted[atom.idAtom] == nil {
            let neighbor = bonds.compactMap { bond -> Int? in
                if bond.idAtom1 == atom.idAtom { return bond.idAtom2 }
                if bond.idAtom2 == atom.idAtom { return bond.idAtom1 }
                return nil
            }.first { fitted[$0] != nil }
            fitted[atom.idAtom] = neighbor.flatMap { fitted[$0] } ?? CGPoint(x: size.width / 2, y: size.height / 2)
        }
        return fitted
    }

    //centers the points in the view and zooms so they fit (but never bigger than maxScale)
    private func fit(_ points: [(id: Int, x: CGFloat, y: CGFloat)], in size: CGSize, maxScale: CGFloat) -> [Int: CGPoint] {
        guard !points.isEmpty else { return [:] }
        let margin: CGFloat = 40
        let minX = points.map(\.x).min()!, maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!, maxY = points.map(\.y).max()!
        let usableWidth = max(1, size.width - margin * 2)
        let usableHeight = max(1, size.height - margin * 2)
        let scale = min(
            maxScale,
            maxX > minX ? usableWidth / (maxX - minX) : maxScale,
            maxY > minY ? usableHeight / (maxY - minY) : maxScale
        )
        let centerX = (minX + maxX) / 2, centerY = (minY + maxY) / 2
        var result: [Int: CGPoint] = [:]
        for point in points {
            result[point.id] = CGPoint(
                x: size.width / 2 + (point.x - centerX) * scale,
                y: size.height / 2 - (point.y - centerY) * scale //y goes up in the molecule, down on screen
            )
        }
        return result
    }

    // MARK: - drawing pieces

    private func drawBond(from start: CGPoint, to end: CGPoint, type: BondType, opacity: CGFloat, width: CGFloat = 3, in context: inout GraphicsContext) {
        guard opacity > 0.01 else { return }
        let dx = end.x - start.x, dy = end.y - start.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0.5 else { return }
        let side = CGPoint(x: -dy / length, y: dx / length) //sideways, to space out double/triple lines
        let count = ElectronLayout.bondOrder(type)
        for line in 0..<count {
            let offset = (CGFloat(line) - CGFloat(count - 1) / 2) * 6
            var path = Path()
            path.move(to: CGPoint(x: start.x + side.x * offset, y: start.y + side.y * offset))
            path.addLine(to: CGPoint(x: end.x + side.x * offset, y: end.y + side.y * offset))
            context.stroke(path, with: .color(.gray.opacity(Double(opacity))), style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
    }

    private func drawElectrons(shown: [Int: CGPoint], in context: inout GraphicsContext) {
        for atom in atoms {
            guard let point = shown[atom.idAtom],
                  let electrons = ElectronLayout.count(for: atom, bonds: bonds),
                  !electrons.isEmpty else { continue }
            let center = SIMD3<Float>(Float(point.x), Float(point.y), 0)
            let bondDirections: [SIMD3<Float>] = bonds.compactMap { bond in
                let otherID: Int
                if bond.idAtom1 == atom.idAtom {
                    otherID = bond.idAtom2
                } else if bond.idAtom2 == atom.idAtom {
                    otherID = bond.idAtom1
                } else {
                    return nil //this bond isn't attached to this atom
                }
                guard let other = shown[otherID] else { return nil }
                return SIMD3(Float(other.x), Float(other.y), 0) - center
            }
            let dots = ElectronLayout.dotPositions(
                center: center,
                bondDirections: bondDirections,
                electrons: electrons,
                distance: 19,
                pairSpacing: 10, //wide enough that the two outlined dots don't overlap
                candidates: ElectronLayout.screenDirections,
                sideways: SIMD3(0, 0, 1)
            )
            for dot in dots {
                //same color as its atom, with a black border so light colors (like H) still show up
                let r: CGFloat = 3.5
                let circle = Path(ellipseIn: CGRect(x: CGFloat(dot.x) - r, y: CGFloat(dot.y) - r, width: r * 2, height: r * 2))
                context.fill(circle, with: .color(Elements.color(for: atom.name)))
                context.stroke(circle, with: .color(.black), lineWidth: 1)
            }
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
}
