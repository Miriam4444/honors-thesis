//
//  ElementsSidebarView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//

//this is just a prototype, eventally i want to have all of the elements but i need to meet with Dr. Jose first

import SwiftUI

struct ElementsSidebarView: View {
    let elements = ["H", "C", "O"]
    
    var body: some View {
        VStack {
            Text("elements")
                .font(.headline)
            ForEach(elements, id: \.self) {
                element in Text(element)
                    .padding()
                    .background(Color .purple.opacity(0.4)
                        .cornerRadius(4)
                        .draggable(element))
            }
        }
        .padding()
    }
}
