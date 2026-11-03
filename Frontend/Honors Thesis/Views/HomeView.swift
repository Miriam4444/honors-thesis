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
    @ObservedObject var auth: AuthManager
    @StateObject private var homeVM = HomeVM()
    @State private var showBuilder = false
    @State private var editingNoteID: Int? = nil //the home page note open in the editor
    @State private var addingNote = false

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

            Section {
                if homeVM.userNotes.isEmpty && !homeVM.isLoading {
                    Text("No notes yet")
                        .foregroundStyle(.secondary)
                }
                //tap a note to edit it, swipe it to delete it
                ForEach(homeVM.userNotes) { note in
                    Button {
                        editingNoteID = note.id
                    } label: {
                        NoteRow(name: note.name, text: note.note)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await homeVM.deleteNote(note) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Notes")
                    Spacer()
                    Button {
                        addingNote = true
                    } label: {
                        Label("New note", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    .textCase(nil) //section headers are all caps on iPhone; keep the button normal
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
            //who's signed in + log out
            ToolbarItem(placement: .navigation) {
                Menu {
                    if let email = auth.email {
                        Text("Signed in as \(email)")
                    }
                    Button(role: .destructive) {
                        Task { await auth.logout() }
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Label("Account", systemImage: "person.crop.circle")
                }
            }
        }
        //new home page note
        .sheet(isPresented: $addingNote) {
            NoteEditorView(isNew: true,
                           onSave: { title, text in
                               await homeVM.addNote(name: title, text: text, userID: builderVM.currentUserID)
                           },
                           onClose: { addingNote = false })
                .padding()
                .presentationDetents([.medium, .large])
        }
        //edit an existing home page note
        .sheet(isPresented: Binding(
            get: { editingNoteID != nil },
            set: { if !$0 { editingNoteID = nil } }
        )) {
            if let note = homeVM.userNotes.first(where: { $0.id == editingNoteID }) {
                NoteEditorView(title: note.name, text: note.note ?? "", isNew: false,
                               onSave: { title, text in await homeVM.updateNote(note, name: title, text: text) },
                               onDelete: { await homeVM.deleteNote(note) },
                               onClose: { editingNoteID = nil })
                    .padding()
                    .presentationDetents([.medium, .large])
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
        HomeView(builderVM: MoleculeBuilderVM(), auth: AuthManager())
    }
}
