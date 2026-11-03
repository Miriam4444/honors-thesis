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
    //who's logged in (shared so it survives the vision pro window closing and reopening)
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        //window: home page (and the builder on iPhone/iPad/Mac)
        //on vision pro this window closes while you're building and comes back when you hit Done
        WindowGroup(id: MoleculeBuilderVM.mainWindowID) {
            ContentView(viewModel: viewModel, auth: auth)
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
