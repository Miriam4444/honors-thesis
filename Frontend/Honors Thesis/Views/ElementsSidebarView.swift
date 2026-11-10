//
//  ElementsSidebarView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/22/26.
//
//the row of element buttons on iPhone (iPad/Mac/Vision Pro use BuilderSidebarView instead).
//the common elements are right there; "More" opens every element with a search bar.
//colors come from Elements.swift, same as everywhere else.

import SwiftUI

struct ElementsSidebarView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    //vertical = sidebar and horizontal = row across the top/bottom
    var axis: Axis = .vertical

    @State private var showAllElements = false

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
            ForEach(Elements.common) { element in
                elementButton(element, size: 60, font: .title2)
            }

            //everything else in the periodic table
            Button {
                showAllElements = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "square.grid.3x3")
                    Text("More").font(.caption)
                }
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(axis == .vertical ? 16 : 8)
        .frame(width: axis == .vertical ? 110 : nil)
        .sheet(isPresented: $showAllElements) {
            AllElementsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
    }

    //tap = quick add near the middle; drag = drop it exactly where you want
    private func elementButton(_ element: ElementInfo, size: CGFloat, font: Font) -> some View {
        Button {
            viewModel.addAtomNearCenter(element: element.symbol)
        } label: {
            Text(element.symbol)
                .font(font)
                .foregroundStyle(Elements.labelColor(for: element.symbol)) //white letters on dark atoms like carbon
                .frame(width: size, height: size)
                .background(Elements.color(for: element.symbol).opacity(0.85))
                .cornerRadius(8)
                .overlay(
                    //a thin outline so white (H) still shows up on a white background
                    RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        #if !os(visionOS)
        //(you can't drag from the panel out into the room on Vision Pro, so it's left off there)
        .draggable(element.symbol)
        #endif
    }
}

//every element, with a search bar. tapping one adds it and closes the sheet
private struct AllElementsSheet: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 8)] //as many across as fit

    private var filteredElements: [ElementInfo] {
        let text = search.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return Elements.all }
        return Elements.all.filter {
            $0.symbol.localizedCaseInsensitiveContains(text) || $0.name.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(filteredElements) { element in
                        Button {
                            viewModel.addAtomNearCenter(element: element.symbol)
                            dismiss()
                        } label: {
                            VStack(spacing: 0) {
                                Text("\(element.number)")
                                    .font(.system(size: 9))
                                Text(element.symbol)
                                    .font(.headline)
                            }
                            .foregroundStyle(Elements.labelColor(for: element.symbol))
                            .frame(width: 52, height: 52)
                            .background(Elements.color(for: element.symbol).opacity(0.85))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(element.name)
                    }
                }
                .padding()
            }
            .searchable(text: $search, prompt: "Search by name or symbol")
            .navigationTitle("All elements")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
