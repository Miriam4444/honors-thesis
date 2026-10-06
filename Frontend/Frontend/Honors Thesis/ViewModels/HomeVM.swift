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
}
