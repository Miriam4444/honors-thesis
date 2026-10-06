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
    //vertical = sidebar and horizontal = row across the top/bottom
    var axis: Axis = .vertical
    let elements = ["H", "C", "O"]

    var body: some View {
        let layout = axis == .vertical ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            Text("Elements")
                .font(.headline)
            #if os(visionOS)
            Text("Tap to add")
                .font(.caption)
                .foregroundStyle(.secondary)
            #endif
            ForEach(elements, id: \.self) { element in
                Button {
                    viewModel.addAtomNearCenter(element: element) // tap = quick add
                } label: {
                    Text(element)
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.purple.opacity(0.4))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                #if !os(visionOS)
                //drag = drop it exactly where you want (only on screens; you can't drag from the panel out into the room on Vision Pro, so it's left off there)
                .draggable(element)
                #endif
            }
            Spacer()
        }
        .padding(axis == .vertical ? 16 : 8)
        .frame(width: axis == .vertical ? 110 : nil)
    }
}
