//
//  HomeVM.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/6/26.
//

//Loads home page with user's saved molecules and notes.

import SwiftUI
import Combine

class HomeVM: ObservableObject {
    @Published var molecules: [Molecule] = []
    @Published var userNotes: [UserNote] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func load(userID: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            async let molecules = MoleculeService.fetchMolecules(userID: userID)
            async let notes = MoleculeService.fetchUserNotes(userID: userID)
            self.molecules = try await molecules
            self.userNotes = try await notes
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - home page notes
    //each returns false if the backend call failed (errorMessage says why), so the editor can stay open

    @discardableResult
    func addNote(name: String, text: String, userID: Int) async -> Bool {
        do {
            let note = try await MoleculeService.addUserNote(name: name, text: Self.cleaned(text), userID: userID)
            userNotes.append(note)
            return true
        } catch {
            errorMessage = "Couldn't add the note: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func updateNote(_ note: UserNote, name: String, text: String) async -> Bool {
        let noteText = Self.cleaned(text)
        do {
            try await MoleculeService.updateUserNote(id: note.idUserNotes, name: name, text: noteText)
            if let index = userNotes.firstIndex(where: { $0.id == note.id }) {
                userNotes[index].name = name
                userNotes[index].note = noteText
            }
            return true
        } catch {
            errorMessage = "Couldn't update the note: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func deleteNote(_ note: UserNote) async -> Bool {
        do {
            try await MoleculeService.deleteUserNote(id: note.idUserNotes)
            userNotes.removeAll { $0.id == note.id }
            return true
        } catch {
            errorMessage = "Couldn't delete the note: \(error.localizedDescription)"
            return false
        }
    }

    //empty text is saved as "no text" (nil) instead of an empty string
    private static func cleaned(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
