//
//  BondSidebarView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

import SwiftUI

struct BondSidebarView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    //vertical = sidebar (Vision Pro, iPad, Mac) and horizontal = a row across the top/bottom (iPhone)
    var axis: Axis = .vertical

    var body: some View {
        let layout = axis == .vertical ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Text("Bonds")
                .font(.headline)
            ForEach([BondType.single, .double, .triple], id: \.self) { type in
                Button {
                    viewModel.toggleBondType(type) // tap again to turn it off
                } label: {
                    Text(type.rawValue.capitalized)
                        .frame(width: 80, height: 44)
                        .background(viewModel.selectedBondType == type ? Color.green.opacity(0.4) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(axis == .vertical ? 16 : 8)
        .frame(width: axis == .vertical ? 120 : nil)
    }
}
