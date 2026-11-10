//
//  DiagramPanelView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/27/26.
//the "view diagram" panel on vision pro: pick Lewis or bond-line, press play,
//and the floating molecule morphs into that flat diagram. "Back to 3D" morphs it back.

import SwiftUI

struct DiagramPanelView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("View diagram").font(.title3.bold())
                Spacer()
                Button {
                    viewModel.toggleDiagramPanel() //closing it also morphs the molecule back
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }

            Picker("Diagram", selection: $viewModel.diagramKind) {
                ForEach(DiagramKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            AxialEquatorialControls(viewModel: viewModel)

            if viewModel.canShowDiagram {
                HStack(spacing: 12) {
                    Button {
                        viewModel.playDiagram()
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.diagramProgress >= 1)

                    Button {
                        viewModel.morphBackTo3D()
                    } label: {
                        Label("Back to 3D", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.diagramProgress == 0)
                }
                Text(viewModel.isShowingDiagram
                     ? "Editing is paused while you're looking at the diagram. Drag the bar above to move this panel."
                     : "Press play to watch your molecule flatten into its \(viewModel.diagramKind.rawValue.lowercased()) structure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                //diagrams come from the backend, which needs a molecule that passed validation
                Text("Validate your molecule first, then come back here to see its diagrams.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 340)
    }
}

//chair cyclohexane only: a switch to keep the axial/equatorial bonds in the diagram,
//then "Show axial" / "Show equatorial" checkboxes that color them (either one or both).
//used by this panel (vision pro) and the Diagram tab (iPhone / iPad / Mac)
struct AxialEquatorialControls: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    var body: some View {
        if viewModel.canShowAxialEquatorial {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Axial & equatorial bonds", isOn: $viewModel.showAxialEquatorial)
                if viewModel.showAxialEquatorial {
                    HStack(spacing: 16) {
                        checkbox("Show axial", isOn: $viewModel.highlightAxial, kind: .axial)
                        checkbox("Show equatorial", isOn: $viewModel.highlightEquatorial, kind: .equatorial)
                    }
                }
            }
        } else if viewModel.hasChairInAnotherShape {
            //e.g. looking at the twist-boat: axial/equatorial only means something on a chair
            Text("Axial and equatorial bonds are a chair thing. Pick a Chair shape to see them.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    //SwiftUI only has real checkboxes on Mac, so this is a tappable box + label that works everywhere.
    //the box is drawn in the highlight color, so it doubles as the color key
    private func checkbox(_ title: String, isOn: Binding<Bool>, kind: AxialKind) -> some View {
        let color = Color(red: kind.rgb.red, green: kind.rgb.green, blue: kind.rgb.blue)
        return Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundStyle(color)
                    .font(.title3)
                Text(title)
                    .foregroundStyle(.primary)
                    .fixedSize()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DiagramPanelView(viewModel: MoleculeBuilderVM())
}
