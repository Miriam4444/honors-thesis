//
//  MoleculeBuilderView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI

//the tabs above the molecule on iPhone / iPad / Mac
private enum ViewTab: String, CaseIterable, Identifiable {
    case twoD = "2D"
    case threeD = "3D"
    case diagram = "Diagram"
    var id: String { rawValue }
}

struct MoleculeBuilderView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    @State private var showAddNote = false
    @State private var showInfo = false

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isOpeningSpace = false // stops double-taps while it's opening
    #else
    @State private var viewTab: ViewTab = .twoD // phone/iPad/Mac start in 2D, with tabs for 3D and diagrams
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
        //once the space opens, this window closes itself (see Molecule3DView) and the floating sidebar takes over.
        //the sidebar's Done button closes the space, which brings the home window back
        .task {
            await openSpaceIfNeeded()
        }
        #endif
    }

    // MARK: - layouts

    #if os(visionOS)
    //Vision Pro: everything for building is in the floating sidebar that follows your head
    //(see makeHUD in Molecule3DView). this window only keeps show/hide, because hiding the
    //molecule closes the 3D space, and the sidebar goes away with it
    private var sidebarLayout: some View {
        VStack(spacing: 16) {
            Spacer()
            //you only see this for a second while the space opens (then this window closes),
            //or if opening failed, so there's a button to try again
            Text(viewModel.isSpaceOpen || isOpeningSpace
                 ? "Opening the builder..."
                 : "Show the molecule to keep building")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button(viewModel.isSpaceOpen ? "Hide molecule" : "Show molecule") {
                Task { await toggleSpace() }
            }
            .disabled(isOpeningSpace)
            //is the space really open and how many atoms exist (good for debugging)
            Text("3D space: \(viewModel.isSpaceOpen ? "open" : "closed") · atoms: \(viewModel.atoms.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    #else
    //iPad / Mac: everything for building on the left, molecule + toolbar in the middle
    private var sidebarLayout: some View {
        HStack(spacing: 0) {
            BuilderSidebarView(viewModel: viewModel) {
                showAddNote = true
            }
            VStack(spacing: 8) {
                moleculeArea
                BuilderToolbarView(viewModel: viewModel)
                controls(showsEditingTools: false)
            }
        }
    }
    #endif

    //iPhone: two sidebars become rows above and below
    private var phoneLayout: some View {
        VStack(spacing: 0) {
            //10 common elements don't fit across a phone, so this row scrolls sideways
            ScrollView(.horizontal, showsIndicators: false) {
                ElementsSidebarView(viewModel: viewModel, axis: .horizontal)
            }
            moleculeArea
            BondSidebarView(viewModel: viewModel, axis: .horizontal)
            controls(showsEditingTools: true)
        }
    }

    #if !os(visionOS)
    //the molecule itself with 2D / 3D / Diagram tabs
    private var moleculeArea: some View {
        VStack(spacing: 8) {
            Picker("View", selection: $viewTab) {
                ForEach(ViewTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)

            switch viewTab {
            case .twoD:
                Molecule2DView(viewModel: viewModel)
            case .threeD:
                Molecule3DView(viewModel: viewModel)
            case .diagram:
                DiagramView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
    }
    #else
    private var moleculeArea: some View { EmptyView() } // the molecule lives in the floating space instead
    #endif

    // MARK: - controls

    //name + validate/save/notes buttons.
    //showsEditingTools adds delete, the move toggle and the status line (only the iPhone needs these here,
    //everywhere else they're in BuilderToolbarView)
    private func controls(showsEditingTools: Bool) -> some View {
        VStack(spacing: 8) {
            TextField("Molecule name", text: $viewModel.moleculeName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)

            if showsEditingTools {
                HStack {
                    Button {
                        viewModel.toggleDeleteMode()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isDeleteMode ? .red : .gray)

                    //what dragging moves
                    Picker("Drag moves", selection: $viewModel.moveMode) {
                        ForEach(MoveMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: 320)

                //iPhone has no sidebar for these, so they live here
                Toggle("Show electrons", isOn: $viewModel.showElectrons)
                    .frame(maxWidth: 320)
                ShapePicker(viewModel: viewModel)
            }

            if showsStatus(showsEditingTools) {
                Text(viewModel.statusMessage)
                    .font(.callout)
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button("Clear", role: .destructive) {
                    viewModel.clear()
                }

                Button("Validate") {
                    viewModel.validate()
                }
                .disabled(viewModel.isValidating)

                Button(viewModel.isSaving ? "Saving..." : "Save") {
                    viewModel.save()
                }
                .disabled(!viewModel.canSave) //locked until validate passes
            }

            HStack(spacing: 16) {
                //iPhone only: everywhere else the notes button lives in the sidebar
                if showsEditingTools {
                    Button {
                        showAddNote = true
                    } label: {
                        Label(notesButtonTitle, systemImage: "note.text")
                    }
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

    //iPad/Mac: BuilderToolbarView already shows the status under the molecule, so only the iPhone needs it here
    //(vision pro doesn't use these controls at all anymore, it's all in the floating sidebar)
    private func showsStatus(_ showsEditingTools: Bool) -> Bool {
        showsEditingTools
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
