//
//  ElementsSidebarView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

//this is just a prototype, eventally i want to have all of the elements but i need to meet with Dr. Jose first

import SwiftUI

struct ElementsSidebarView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    let elements = ["H", "C", "O"]

    var body: some View {
        VStack(spacing: 12) {
            Text("Elements")
                .font(.headline)
            #if os(visionOS)
            Text("Tap to add")
                .font(.caption)
                .foregroundStyle(.secondary)
            #endif
            ForEach(elements, id: \.self) { element in
                Text(element)
                    .font(.title2)
                    .frame(width: 60, height: 60)
                    .background(Color.purple.opacity(0.4))
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.addAtomNearCenter(element: element) // tap = quick add
                    }
                    .draggable(element) // drag = drop it exactly where you want
            }
            Spacer()
        }
        .padding()
        .frame(width: 110)
    }
}
