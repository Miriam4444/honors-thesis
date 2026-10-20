//
//  ShapePicker.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/27/26.
//a compact dropdown for picking which stable 3D shape (conformer) the molecule shows.
//only used on iPhone, which has no sidebar (everywhere else it's the Shapes section in the sidebar).
//it hides itself when the molecule only has one shape.

import SwiftUI

struct ShapePicker: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    var body: some View {
        if viewModel.hasMultipleShapes {
            HStack {
                Text("Shape")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Picker("Shape", selection: Binding(
                    get: { viewModel.selectedConformer },
                    set: { viewModel.selectConformer($0) } //the molecule glides into the new shape
                )) {
                    ForEach(viewModel.conformers.indices, id: \.self) { index in
                        Text(viewModel.conformers[index].label).tag(index)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}
