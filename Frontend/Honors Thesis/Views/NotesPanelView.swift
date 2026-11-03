//
//  NotesPanelView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/20/26.
//the notes sidebar that pops up next to the builder sidebar on vision pro.
//shows this molecule's notes; tap one to edit or delete it, or add a new one.
//(it's a floating panel instead of a sheet because sheets don't work inside the immersive space)

import SwiftUI

struct NotesPanelView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    //what the panel is showing: the list, a new note, or one note being edited
    private enum Mode: Equatable {
        case list
        case new
        case editing(String) //the note's id
    }
    @State private var mode: Mode = .list

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

            switch mode {
            case .list:
                noteList
            case .new:
                NoteEditorView(isNew: true,
                               onSave: { title, text in
                                   await viewModel.addNote(name: title, text: text)
                                   return true
                               },
                               onClose: { mode = .list })
            case .editing(let noteID):
                if let note = viewModel.notes.first(where: { $0.id == noteID }) {
                    NoteEditorView(title: note.name, text: note.note ?? "", isNew: false,
                                   onSave: { title, text in await viewModel.updateNote(note, name: title, text: text) },
                                   onDelete: { await viewModel.deleteNote(note) },
                                   onClose: { mode = .list })
                } else {
                    noteList //the note is gone (e.g. deleted), so just show the list
                }
            }
        }
        .padding(16)
        .frame(width: 300)
        .onChange(of: viewModel.savedMoleculeID) { mode = .list } //a different molecule was opened
    }

    private var noteList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.notes.isEmpty {
                        Text("No notes yet")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.notes) { note in
                        Button {
                            mode = .editing(note.id)
                        } label: {
                            NoteRow(name: note.name, text: note.note, notSavedYet: note.idMoleculeNotes == nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 220)

            Button {
                mode = .new
            } label: {
                Label("New note", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

//one note in a list: title, a preview of the text, and an arrow hinting you can tap it
struct NoteRow: View {
    let name: String
    let text: String?
    var notSavedYet = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name).font(.headline)
                    if notSavedYet {
                        Text("not saved yet") //added before the molecule was saved
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                if let text, !text.isEmpty {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) //the whole row is tappable, not just the text
    }
}

#Preview {
    NotesPanelView(viewModel: MoleculeBuilderVM())
}
