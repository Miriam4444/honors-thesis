//
//  NoteEditorView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 11/3/26.
//
//  NoteEditorView.swift
//  Honors Thesis
//
//the one note editor used everywhere: molecule notes (vision pro panel + iPad/iPhone sheet)
//and the home page notes. title + text, then Save / Cancel / Delete.
//
//delete asks twice (tap Delete, then "Tap again to delete") instead of a popup,
//because popups don't show up inside the vision pro floating panels.

import SwiftUI

struct NoteEditorView: View {
    let isNew: Bool //new note = no Delete button and "Add" instead of "Save"
    //these return true if it worked (then the editor closes), false to stay open (e.g. the backend was unreachable)
    let onSave: (_ title: String, _ text: String) async -> Bool
    var onDelete: (() async -> Bool)? = nil
    let onClose: () -> Void

    @State private var title: String
    @State private var text: String
    @State private var isWorking = false
    @State private var confirmingDelete = false

    init(title: String = "", text: String = "", isNew: Bool,
         onSave: @escaping (_ title: String, _ text: String) async -> Bool,
         onDelete: (() async -> Bool)? = nil,
         onClose: @escaping () -> Void) {
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
        self.onClose = onClose
        _title = State(initialValue: title)
        _text = State(initialValue: text)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isNew ? "New note" : "Edit note")
                .font(.headline)

            TextField("Title", text: $title) //the database needs a name for every note
                .textFieldStyle(.roundedBorder)
            TextField("Write something...", text: $text, axis: .vertical)
                .lineLimit(4...10)
                .textFieldStyle(.roundedBorder)

            HStack {
                if let onDelete, !isNew {
                    //(no role: .destructive here: that makes the text red, which disappears on a red button)
                    Button {
                        if confirmingDelete {
                            run { await onDelete() }
                        } else {
                            confirmingDelete = true //first tap just asks
                        }
                    } label: {
                        //icon + words spelled out (a Label can shrink to just the icon in tight spots)
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text(confirmingDelete ? "Tap again to delete" : "Delete note")
                                .fixedSize() //never cut the words off
                        }
                        .foregroundStyle(.white) //white on the red button
                    }
                    .buttonStyle(.borderedProminent) //solid red so it clearly stands apart from Save/Cancel
                    .tint(.red)
                }

                Spacer()

                Button("Cancel", action: onClose)
                    .buttonStyle(.bordered)

                Button(isWorking ? "Saving..." : (isNew ? "Add" : "Save")) {
                    run { await onSave(trimmedTitle, text) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedTitle.isEmpty || isWorking)
            }
            .disabled(isWorking)
        }
        //typing again cancels a half-finished delete
        .onChange(of: title) { confirmingDelete = false }
        .onChange(of: text) { confirmingDelete = false }
    }

    //runs a save/delete, and closes the editor only if it worked
    private func run(_ action: @escaping () async -> Bool) {
        isWorking = true
        Task {
            let worked = await action()
            isWorking = false
            confirmingDelete = false
            if worked { onClose() }
        }
    }
}

#Preview {
    NoteEditorView(title: "Bond angles", text: "Water is about 104.5 degrees", isNew: false,
                   onSave: { _, _ in true }, onDelete: { true }, onClose: {})
        .padding()
}
