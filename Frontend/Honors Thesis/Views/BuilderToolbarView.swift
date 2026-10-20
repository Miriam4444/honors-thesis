//
//  BuilderToolbarView.swift
//  Honors Thesis
//
//delete mode + what a drag moves (one atom or the whole molecule) + the status line.
//isCompact = stacked up to fit inside the vision pro sidebar
//not compact = one wide row under the molecule on iPad/Mac

import SwiftUI

struct BuilderToolbarView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    var isCompact = false

    var body: some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 10) {
                deleteButton
                    .frame(maxWidth: .infinity)
                moveModePicker
                statusText
            }
        } else {
            VStack(spacing: 10) {
                HStack(spacing: 14) {
                    deleteButton
                    moveModePicker
                        .frame(width: 240)
                }
                statusText
                    .frame(width: 380)
            }
            .padding(14)
        }
    }

    private var deleteButton: some View {
        Button {
            viewModel.toggleDeleteMode()
        } label: {
            Label(viewModel.isDeleteMode ? "Deleting" : "Delete", systemImage: "trash")
                .frame(minWidth: 110)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.isDeleteMode ? .red : .gray)
    }

    private var moveModePicker: some View {
        Picker("Drag moves", selection: $viewModel.moveMode) {
            ForEach(MoveMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var statusText: some View {
        Text(viewModel.statusMessage)
            .font(.callout)
            .foregroundStyle(statusColor)
            .multilineTextAlignment(isCompact ? .leading : .center)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true) //wrap instead of cutting off
    }

    private var statusColor: Color {
        if viewModel.isDeleteMode { return .red }
        switch viewModel.validationState {
        case .valid: return .green
        case .invalid: return .red
        case .notChecked: return .secondary
        }
    }
}

#Preview {
    BuilderToolbarView(viewModel: MoleculeBuilderVM())
}
