//
//  MoleculeBuilderView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI

struct MoleculeBuilderView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    @State private var showAddNote = false
    @State private var showInfo = false

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpeningSpace = false // stops double-taps while it's opening
    #else
    @State private var show3D = false // phone/iPad/Mac start in 2D, with a switch to 3D
    #endif

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isPhoneLayout: Bool { horizontalSizeClass == .compact }
    #else
    private var isPhoneLayout: Bool { false }
    #endif

    var body: some View {
        Group {
            if isPhoneLayout {
                phoneLayout
            } else {
                sidebarLayout
            }
        }
        .navigationTitle(viewModel.moleculeName.isEmpty ? "New molecule" : viewModel.moleculeName)
        .overlay {
            if viewModel.isLoading { ProgressView() }
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(viewModel: viewModel)
        }
        //TODO: swap this for a real info screen once the backend validation sends structure info
        .alert("Molecule info", isPresented: $showInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("this will have stuff when i build in validation")
        }
        #if os(visionOS)
        //opening the builder (new or saved molecule) brings up the floating molecule right away
        .task {
            await openSpaceIfNeeded()
        }
        //going back to home page puts floating molecule away too
        .onDisappear {
            if viewModel.isSpaceOpen {
                Task { await dismissImmersiveSpace() }
            }
        }
        #endif
    }

    // MARK: - layouts

    //Vision Pro / iPad / Mac: elements on the left, bonds on the right
    private var sidebarLayout: some View {
        HStack(spacing: 0) {
            ElementsSidebarView(viewModel: viewModel)

            #if os(visionOS)
            //molecule floats in the room, so the middle is just controls
            VStack(spacing: 16) {
                Spacer()
                controls
                Button(viewModel.isSpaceOpen ? "Hide molecule" : "Show molecule") {
                    Task { await toggleSpace() }
                }
                .disabled(isOpeningSpace)
                //is the space really open and how many atoms exist (god for debugging)
                Text("3D space: \(viewModel.isSpaceOpen ? "open" : "closed") · atoms: \(viewModel.atoms.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            #else
            VStack {
                moleculeArea
                controls
            }
            #endif

            BondSidebarView(viewModel: viewModel)
        }
    }

    //iPhone: two sidebars become rows above and below
    private var phoneLayout: some View {
        VStack(spacing: 0) {
            ElementsSidebarView(viewModel: viewModel, axis: .horizontal)
            moleculeArea
            BondSidebarView(viewModel: viewModel, axis: .horizontal)
            controls
        }
    }

    #if !os(visionOS)
    //the molecule itself with a 2D/3D switch
    private var moleculeArea: some View {
        VStack(spacing: 8) {
            Picker("View", selection: $show3D) {
                Text("2D").tag(false)
                Text("3D").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 160)

            if show3D {
                Molecule3DView(viewModel: viewModel)
            } else {
                Molecule2DView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
    }
    #else
    private var moleculeArea: some View { EmptyView() } // the molecule lives in the floating space instead
    #endif

    // MARK: - controls

    //name, move toggle, status, and the buttons
    private var controls: some View {
        VStack(spacing: 8) {
            TextField("Molecule name", text: $viewModel.moleculeName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)

            //what dragging moves
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

            HStack(spacing: 16) {
                Button {
                    showAddNote = true
                } label: {
                    Label(notesButtonTitle, systemImage: "note.text")
                }

                Button {
                    showInfo = true
                } label: {
                    Label("See info", systemImage: "info.circle")
                }
                .disabled(!viewModel.canSeeInfo) // only after validation passes
            }
        }
        .padding()
    }

    private var notesButtonTitle: String {
        viewModel.notes.isEmpty ? "Add note" : "Notes (\(viewModel.notes.count))"
    }

    #if os(visionOS)
    private func toggleSpace() async {
        if viewModel.isSpaceOpen {
            await dismissImmersiveSpace()
            return // onDisappear in the space flips isSpaceOpen back to false
        }
        await openSpaceIfNeeded()
    }

    private func openSpaceIfNeeded() async {
        guard !viewModel.isSpaceOpen, !isOpeningSpace else { return } // already open or on its way
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
    NavigationStack {
        MoleculeBuilderView(viewModel: MoleculeBuilderVM())
    }
}
