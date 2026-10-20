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

#Preview {
    DiagramPanelView(viewModel: MoleculeBuilderVM())
}
