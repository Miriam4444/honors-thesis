//
//  LoginView.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 11/3/26.
//the first screen when you're not logged in. both buttons open the WorkOS login page
//(it handles passwords, "forgot password", etc. for us); "Create account" just starts
//on its sign-up screen instead of sign-in.

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var auth: AuthManager
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession //the secure login browser sheet

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "atom")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Molecule Builder")
                .font(.largeTitle.bold())
            Text("Build molecules in 2D, 3D, and in your room.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button {
                    Task { await auth.login(using: webAuthenticationSession) }
                } label: {
                    Text("Sign in")
                        .frame(maxWidth: 260)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    Task { await auth.login(using: webAuthenticationSession, signUp: true) }
                } label: {
                    Text("Create account")
                        .frame(maxWidth: 260)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .disabled(auth.isWorking)

            if auth.isWorking {
                ProgressView("Signing in...")
            }
            if let error = auth.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView(auth: AuthManager())
}
