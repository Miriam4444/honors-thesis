//
//  AddNoteSheetView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/6/26.
//
//Shows this molecule's notes and lets you write a new one.

import SwiftUI

struct AddNoteSheet: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var text = ""
    @State private var isSaving = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New note") {
                    TextField("Title", text: $title) // the database needs a name for every note
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                }

                if !viewModel.notes.isEmpty {
                    Section("Notes on this molecule") {
                        ForEach(viewModel.notes) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(note.name).font(.headline)
                                    if note.idMoleculeNotes == nil {
                                        // added before the molecule was saved
                                        Text("not saved yet")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                if let noteText = note.note {
                                    Text(noteText)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Add") {
                        Task {
                            isSaving = true
                            await viewModel.addNote(
                                name: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                text: text
                            )
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 450) // mac sheets start tiny otherwise
        #endif
    }
}
