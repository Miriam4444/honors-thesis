//
//  AddNoteSheetView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/6/26.
//
//This molecule's notes on iPhone / iPad / Mac: tap a note to edit it, swipe it to delete it,
//or tap + to add a new one. (Vision Pro uses NotesPanelView instead.)

import SwiftUI

struct AddNoteSheet: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    @Environment(\.dismiss) private var dismiss

    @State private var editingNoteID: String? = nil //the note open in the editor
    @State private var addingNote = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.notes.isEmpty {
                    Text("No notes yet. Tap + to add one.")
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.notes) { note in
                    Button {
                        editingNoteID = note.id
                    } label: {
                        NoteRow(name: note.name, text: note.note, notSavedYet: note.idMoleculeNotes == nil)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteNote(note) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addingNote = true
                    } label: {
                        Label("New note", systemImage: "plus")
                    }
                }
            }
            //new note
            .sheet(isPresented: $addingNote) {
                NoteEditorView(isNew: true,
                               onSave: { title, text in
                                   await viewModel.addNote(name: title, text: text)
                                   return true
                               },
                               onClose: { addingNote = false })
                    .padding()
                    .presentationDetents([.medium, .large])
            }
            //edit an existing note
            .sheet(isPresented: Binding(
                get: { editingNoteID != nil },
                set: { if !$0 { editingNoteID = nil } }
            )) {
                if let note = viewModel.notes.first(where: { $0.id == editingNoteID }) {
                    NoteEditorView(title: note.name, text: note.note ?? "", isNew: false,
                                   onSave: { title, text in await viewModel.updateNote(note, name: title, text: text) },
                                   onDelete: { await viewModel.deleteNote(note) },
                                   onClose: { editingNoteID = nil })
                        .padding()
                        .presentationDetents([.medium, .large])
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 450) // mac sheets start tiny otherwise
        #endif
    }
}

#Preview {
    AddNoteSheet(viewModel: MoleculeBuilderVM())
}
