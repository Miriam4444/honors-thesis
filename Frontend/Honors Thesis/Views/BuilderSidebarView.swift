//
//  BuilderSidebarView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/20/26.
//the one sidebar with everything for building, top to bottom:
//(vision pro only: name + validate/save, then delete + move toggle + status)
//common atoms -> scrolling list of every element -> bonds -> notes button
//on vision pro it floats next to you, on iPad/Mac it's the left column

import SwiftUI

struct BuilderSidebarView: View {
    @ObservedObject var viewModel: MoleculeBuilderVM
    //true on vision pro: the sidebar also holds what used to be in the big window and the little middle screen
    var showsMoleculeControls = false
    //vision pro: closes the 3D space and goes back to the home page (nil = no Done button)
    var onDone: (() -> Void)? = nil
    //vision pro: opens the "view diagram" panel (nil = no button; iPad/Mac use the Diagram tab instead)
    var onDiagramTapped: (() -> Void)? = nil
    var onNotesTapped: () -> Void

    @State private var search = ""
    @State private var showInfo = false
    @State private var showShapeList = false

    //common ones are big, the full list is smaller so lots fit
    private let commonColumns = Array(repeating: GridItem(.fixed(52), spacing: 8), count: 3)
    private let allColumns = Array(repeating: GridItem(.fixed(40), spacing: 6), count: 4)

    private var filteredElements: [ElementInfo] {
        let text = search.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return Elements.all }
        return Elements.all.filter {
            $0.symbol.localizedCaseInsensitiveContains(text) || $0.name.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsMoleculeControls {
                moleculeControls
                Divider()
                sectionTitle("Edit")
                BuilderToolbarView(viewModel: viewModel, isCompact: true)
                Divider()
            }

            // MARK: common atoms
            sectionTitle("Common atoms")
            LazyVGrid(columns: commonColumns, spacing: 8) {
                ForEach(Elements.common) { element in
                    elementButton(element, size: 52, font: .title3)
                }
            }

            // MARK: every element
            sectionTitle("All elements")
            TextField("Search", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(width: 178)
            ScrollView {
                LazyVGrid(columns: allColumns, spacing: 6) {
                    ForEach(filteredElements) { element in
                        elementButton(element, size: 40, font: .callout)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: showsMoleculeControls ? 140 : 190) //shorter on vision pro since the sidebar has more in it

            // MARK: bonds
            sectionTitle("Bonds")
            HStack(spacing: 6) {
                ForEach([BondType.single, .double, .triple], id: \.self) { type in
                    Button {
                        viewModel.toggleBondType(type) //tap again to turn it off
                    } label: {
                        Text(type.rawValue.capitalized)
                            .font(.callout)
                            .frame(width: 56, height: 40)
                            .background(viewModel.selectedBondType == type ? Color.green.opacity(0.45) : Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // MARK: shapes (only when the molecule can take more than one stable 3D shape)
            if viewModel.hasMultipleShapes {
                shapesSection
            }

            // MARK: view (electrons + diagrams)
            sectionTitle("View")
            Toggle("Show electrons", isOn: $viewModel.showElectrons) //lone pairs + unpaired electrons as dots
            if let onDiagramTapped {
                Button(action: onDiagramTapped) {
                    Label("View diagram", systemImage: "square.on.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // MARK: notes
            Button(action: onNotesTapped) {
                Label(notesTitle, systemImage: "note.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .frame(width: showsMoleculeControls ? 260 : 210)
    }

    // MARK: - shapes

    //the current shape with arrows to step through them, plus a list you can pull up
    private var shapesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionTitle("Shapes (\(viewModel.conformers.count))")
                Spacer()
                Button(showShapeList ? "Hide list" : "Show list") {
                    showShapeList.toggle()
                }
                .buttonStyle(.borderless)
                .font(.callout)
            }

            //step through them one at a time
            HStack {
                Button { viewModel.previousConformer() } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.bordered)
                Text(viewModel.conformers.indices.contains(viewModel.selectedConformer)
                     ? viewModel.conformers[viewModel.selectedConformer].name : "")
                    .font(.callout.bold())
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                Button { viewModel.nextConformer() } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.bordered)
            }

            if showShapeList {
                ForEach(viewModel.conformers.indices, id: \.self) { index in
                    let shape = viewModel.conformers[index]
                    Button {
                        viewModel.selectConformer(index)
                    } label: {
                        HStack {
                            Image(systemName: index == viewModel.selectedConformer ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading) {
                                Text(shape.name).font(.callout)
                                Text(shape.relativeEnergy < 0.05 ? "most stable" : String(format: "+%.1f kJ/mol", shape.relativeEnergy))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - name, validate, save (what used to be in the big window)

    private var moleculeControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Molecule")
                Spacer()
                if let onDone {
                    Button("Done", action: onDone) //unsaved changes are lost, so save first
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            TextField("Molecule name", text: $viewModel.moleculeName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 6) {
                Button("Clear", role: .destructive) {
                    viewModel.clear()
                }
                Button("Validate") {
                    viewModel.validate()
                }
                .disabled(viewModel.isValidating)
                Button(viewModel.isSaving ? "Saving..." : "Save") {
                    viewModel.save()
                }
                .disabled(!viewModel.canSave) //locked until validate passes
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                showInfo.toggle()
            } label: {
                Label("See info", systemImage: "info.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canSeeInfo) //only after validation passes

            //TODO: swap this for real structure info from the backend
            //(it's inline instead of an alert because alerts don't show up in the floating panel)
            if showInfo && viewModel.canSeeInfo {
                Text("this will have stuff when i build in validation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var notesTitle: String {
        viewModel.notes.isEmpty ? "Notes" : "Notes (\(viewModel.notes.count))"
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }

    //tap = add it near the middle. on iPad/Mac you can also drag it to an exact spot
    private func elementButton(_ element: ElementInfo, size: CGFloat, font: Font) -> some View {
        Button {
            viewModel.addAtomNearCenter(element: element.symbol)
        } label: {
            Text(element.symbol)
                .font(font)
                .foregroundStyle(Elements.labelColor(for: element.symbol))
                .frame(width: size, height: size)
                .background(Elements.color(for: element.symbol).opacity(0.85))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help(element.name) //hover tooltip on Mac
        #if !os(visionOS)
        //you can't drag from a panel out into the room on vision pro, so this is screens only
        .draggable(element.symbol)
        #endif
    }
}

#Preview {
    BuilderSidebarView(viewModel: MoleculeBuilderVM(), onNotesTapped: {})
}
