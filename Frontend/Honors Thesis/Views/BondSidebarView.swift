//
//  BondSidebarView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI

struct BondSidebarView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    
    var body: some View {
        VStack{
            Text("Bonds")
                .font(.headline)
            ForEach([BondType.single, .double, .triple], id: \.self) { type in
                Text(type.rawValue.capitalized)
                    .padding()
                    .background(viewModel.selectedBondType == type ? Color.green.opacity(0.4) : Color.gray.opacity(0.2))
                    .cornerRadius(4)
                        .onTapGesture{
                            viewModel.selectedBondType = type
                        }
            }
        }
        .padding()
    }
}

