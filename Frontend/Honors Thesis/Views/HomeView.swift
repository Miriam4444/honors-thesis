//
//  HomeView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/6/26.
//The user's home page: saved molecules and notes, plus a way to start a new molecule.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var builderVM: MoleculeBuilderVM //shared with builder and floating space)
    @StateObject private var homeVM = HomeVM()
    @State private var showBuilder = false

    var body: some View {
        List {
            //problems talking to the backend show up at the top
            if let error = homeVM.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Button("Try again") {
                        Task { await reload() }
                    }
                }
            }

            Section("Molecules") {
                if homeVM.molecules.isEmpty && !homeVM.isLoading {
                    Text("No saved molecules yet")
                        .foregroundStyle(.secondary)
                }
                ForEach(homeVM.molecules) { molecule in
                    Button {
                        Task {
                            await builderVM.open(molecule)
                            showBuilder = true
                        }
                    } label: {
                        Label(molecule.name, systemImage: "atom")
                    }
                }
            }

            Section("Notes") {
                if homeVM.userNotes.isEmpty && !homeVM.isLoading {
                    Text("No notes yet")
                        .foregroundStyle(.secondary)
                }
                ForEach(homeVM.userNotes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.name)
                            .font(.headline)
                        if let text = note.note, !text.isEmpty {
                            Text(text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .navigationTitle("My Molecules")
        .overlay {
            if homeVM.isLoading && homeVM.molecules.isEmpty {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    builderVM.startNew()
                    showBuilder = true
                } label: {
                    Label("New molecule", systemImage: "plus")
                }
            }
        }
        .navigationDestination(isPresented: $showBuilder) {
            MoleculeBuilderView(viewModel: builderVM)
        }
        .refreshable { await reload() } //pull down to refresh
        // reload every time the home page shows up, so newly saved molecules appear
        .task(id: showBuilder) {
            if !showBuilder { await reload() }
        }
    }

    private func reload() async {
        await homeVM.load(userID: builderVM.currentUserID)
    }
}

#Preview {
    NavigationStack {
        HomeView(builderVM: MoleculeBuilderVM())
    }
}
