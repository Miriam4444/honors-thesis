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
        //home page opens first rn but later the login/registration will go here
        NavigationStack {
            HomeView(builderVM: viewModel)
        }
    }
}

#Preview {
    ContentView(viewModel: MoleculeBuilderVM())
}
