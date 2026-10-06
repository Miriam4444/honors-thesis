//
//  Honors_ThesisApp.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

import SwiftUI

@main
struct Honors_ThesisApp: App {
    // one shared molecule, so the control panel and the floating space show the same thing
    @StateObject private var viewModel = MoleculeBuilderVM()

    var body: some Scene {
        // the window: sidebars + buttons (on iPad/Mac it also shows the molecule)
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        #if os(visionOS)
        .defaultSize(width: 900, height: 450) // just a control panel on vision pro
        #else
        .defaultSize(width: 1200, height: 800)
        #endif

        #if os(visionOS)
        // the room: the molecule floats here with nothing behind it.
        // "mixed" means you still see your real room around it (that's the AR part)
        ImmersiveSpace(id: MoleculeBuilderVM.immersiveSpaceID) {
            Molecule3DView(viewModel: viewModel, isImmersive: true)
                .onAppear { viewModel.isSpaceOpen = true }
                .onDisappear { viewModel.isSpaceOpen = false }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        #endif
    }
}
