//
//  MoleculeBuilderView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI

struct MoleculeBuilderView: View {
    @StateObject var viewModel = MoleculeBuilderVM()
    
    var body: some View {
        HStack {
            ElementsSidebarView()
            
            VStack {
                Molecule3DView(viewModel:viewModel)
                
                Button("save") {
                    viewModel.save()
                }
                .padding()
            }
            
            BondSidebarView(viewModel: viewModel)
        }
    }
}
