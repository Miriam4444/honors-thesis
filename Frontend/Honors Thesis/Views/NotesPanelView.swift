//
//  NotesPanelView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/20/26.
//the notes sidebar that pops up next to the builder sidebar on vision pro.
//same job as AddNoteSheet but built as a floating panel instead of a sheet
//(sheets don't work inside the immersive space)

import SwiftUI

struct NotesPanelView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    @State private var title = ""
    @State private var text = ""
    @State private var isSaving = false

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes").font(.title3.bold())
                Spacer()
                Button {
                    viewModel.showNotesPanel = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }

            //existing notes
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.notes.isEmpty {
                        Text("No notes yet")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.notes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(note.name).font(.headline)
                                if note.idMoleculeNotes == nil {
                                    Text("not saved yet") //added before the molecule was saved
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: 200)

            Divider()

            //new note
            Text("New note").font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Write something...", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)

            Button(isSaving ? "Saving..." : "Add note") {
                Task {
                    isSaving = true
                    await viewModel.addNote(
                        name: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        text: text
                    )
                    isSaving = false
                    title = ""
                    text = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdd)
        }
        .padding(16)
        .frame(width: 280)
    }
}

#Preview {
    NotesPanelView(viewModel: MoleculeBuilderVM())
}

