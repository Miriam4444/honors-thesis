//
//  MoleculeBuilderView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI

struct MoleculeBuilderView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpeningSpace = false // stops double-taps while it's opening
    #endif

    var body: some View {
        HStack(spacing: 0) {
            // left: elements
            ElementsSidebarView(viewModel: viewModel)

            #if os(visionOS)
            // vision pro: the molecule floats in the room, so the middle is just controls
            VStack(spacing: 16) {
                Spacer()
                controls
                Button(viewModel.isSpaceOpen ? "Hide molecule" : "Show molecule") {
                    Task { await toggleSpace() }
                }
                .disabled(isOpeningSpace)
                // helps us debug: is the space really open, and how many atoms exist
                Text("3D space: \(viewModel.isSpaceOpen ? "open" : "closed") · atoms: \(viewModel.atoms.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            #else
            // iPad / Mac: the molecule lives right here in the window
            VStack {
                Molecule3DView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                controls
            }
            #endif

            // right: pick a bond type here, then tap two atoms
            BondSidebarView(viewModel: viewModel)
        }
    }

    // move toggle, status, and the clear/validate/save buttons (same on every device)
    private var controls: some View {
        VStack {
            TextField("Molecule name", text: $viewModel.moleculeName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)

            // what dragging moves: one atom, or everything bonded to it
            Picker("Drag moves", selection: $viewModel.moveMode) {
                ForEach(MoveMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            Text(viewModel.statusMessage)
                .font(.callout)
                .foregroundStyle(statusColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Clear", role: .destructive) {
                    viewModel.clear()
                }

                Button("Validate") {
                    viewModel.validate()
                }

                Button(viewModel.isSaving ? "Saving..." : "Save") {
                    viewModel.save()
                }
                .disabled(!viewModel.canSave) // locked until validate passes
            }
            .padding()
        }
    }

    #if os(visionOS)
    private func toggleSpace() async {
        if viewModel.isSpaceOpen {
            await dismissImmersiveSpace()
            return // onDisappear in the space flips isSpaceOpen back to false
        }
        isOpeningSpace = true
        let result = await openImmersiveSpace(id: MoleculeBuilderVM.immersiveSpaceID)
        isOpeningSpace = false
        switch result {
        case .opened:
            break // onAppear in the space flips isSpaceOpen to true
        case .userCancelled:
            viewModel.statusMessage = "Opening the 3D space was cancelled."
        case .error:
            viewModel.statusMessage = "Couldn't open the 3D space. Check the Xcode console for a red message."
        @unknown default:
            viewModel.statusMessage = "Couldn't open the 3D space."
        }
    }
    #endif

    private var statusColor: Color {
        switch viewModel.validationState {
        case .valid: return .green
        case .invalid: return .red
        case .notChecked: return .secondary
        }
    }
}

#Preview {
    MoleculeBuilderView(viewModel: MoleculeBuilderVM())
}
