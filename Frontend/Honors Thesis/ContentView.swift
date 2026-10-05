//
//  ContentView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM

    var body: some View {
        // the molecule builder is the first screen for now
        // later this is where login/registration will go first
        MoleculeBuilderView(viewModel: viewModel)
    }
}

#Preview {
    ContentView(viewModel: MoleculeBuilderVM())
}
