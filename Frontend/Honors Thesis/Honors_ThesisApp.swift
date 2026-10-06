//
//  Honors_ThesisApp.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 9/17/26.
//

import SwiftUI

@main
struct Honors_ThesisApp: App {
    //create a single shared molecule so everything shows the same thing
    @StateObject private var viewModel = MoleculeBuilderVM()

    var body: some Scene {
        //window: sidebars + buttons
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        #if os(visionOS)
        .defaultSize(width: 900, height: 600) // home page + control panel on vision pro
        #else
        .defaultSize(width: 1200, height: 800)
        #endif

        #if os(visionOS)
        //immersive so u still see your real room around it (that's the AR part)
        ImmersiveSpace(id: MoleculeBuilderVM.immersiveSpaceID) {
            Molecule3DView(viewModel: viewModel, isImmersive: true)
                .onAppear { viewModel.isSpaceOpen = true }
                .onDisappear { viewModel.isSpaceOpen = false }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        #endif
    }
}
