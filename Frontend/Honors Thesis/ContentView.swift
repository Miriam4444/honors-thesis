//
//  ContentView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    @ObservedObject var auth: AuthManager

    var body: some View {
        Group {
            if auth.isRestoring {
                ProgressView("Loading...") //checking the saved login, takes a moment
            } else if auth.isLoggedIn {
                NavigationStack {
                    HomeView(builderVM: viewModel, auth: auth)
                }
            } else {
                LoginView(auth: auth)
            }
        }
        .task { await auth.restore() } //stay logged in from last time if the saved login is still good
        //everything the builder saves belongs to whoever is logged in
        .onChange(of: auth.userID, initial: true) {
            viewModel.currentUserID = auth.userID ?? 0
            if auth.userID == nil { viewModel.startNew() } //don't leave the last person's molecule open
        }
    }
}

#Preview {
    ContentView(viewModel: MoleculeBuilderVM(), auth: AuthManager())
}
