//
//  AuthManagerVM.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 11/3/26.
//
//keeps track of who's logged in.
//
//login, step by step:
//  1. ask our backend for the WorkOS login page (with a random "state" value)
//  2. open that page in a secure browser sheet; the user signs in or creates an account there
//  3. WorkOS sends the browser to honorsthesis://auth/callback?code=...&state=..., which comes back to the app
//  4. check the state matches (so nobody can slip us someone else's login), then send the code to our backend
//  5. the backend gives back our own session token, which we keep in the Keychain and send with every request

import SwiftUI
import Combine
import AuthenticationServices

private struct LoginURLResponse: Decodable { let url: String }
private struct TokenRequest: Encodable { let code: String }
private struct TokenResponse: Decodable { let token: String; let user_id: Int; let email: String }
private struct MeResponse: Decodable { let user_id: Int; let email: String }
private struct MessageResponse: Decodable { let message: String }

class AuthManager: ObservableObject {
    static let callbackScheme = "honorsthesis" //must match the redirect URI in the WorkOS dashboard

    @Published var userID: Int? = nil
    @Published var email: String? = nil
    @Published var isRestoring = true   //checking a saved login when the app opens
    @Published var isWorking = false    //in the middle of signing in
    @Published var errorMessage: String? = nil

    var isLoggedIn: Bool { userID != nil }

    private var expiredObserver: AnyCancellable?

    init() {
        //if the backend ever says our token is no good (expired, logged out elsewhere...), go back to the login screen
        expiredObserver = NotificationCenter.default.publisher(for: .loginExpired)
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                self?.signOutLocally()
                self?.errorMessage = note.object as? String
            }
    }

    // MARK: - staying logged in

    //on launch: if there's a saved token, check it with the backend and skip the login screen if it's still good
    func restore() async {
        guard !isLoggedIn else { isRestoring = false; return } //already logged in (e.g. the window was reopened)
        defer { isRestoring = false }
        guard let token = KeychainStore.loadToken() else { return }
        APIClient.authToken = token
        do {
            let me: MeResponse = try await APIClient.get("auth/me")
            userID = me.user_id
            email = me.email
        } catch APIError.notLoggedIn {
            signOutLocally() //the saved token expired or was logged out
        } catch {
            //backend unreachable: keep the token and try again next launch, but show the login screen for now
            APIClient.authToken = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - login

    //signUp = start on WorkOS's "create account" screen instead of "sign in"
    func login(using session: WebAuthenticationSession, signUp: Bool = false) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            //1. the WorkOS login page, with a random state value to check later
            let state = UUID().uuidString
            let page: LoginURLResponse = try await APIClient.get("auth/login-url", query: [
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "signup", value: signUp ? "true" : "false"),
            ])
            guard let pageURL = URL(string: page.url) else {
                errorMessage = "The backend sent a bad login link"
                return
            }

            //2 + 3. show it; this waits until WorkOS sends the browser back to honorsthesis://...
            //(.ephemeral = a private browser session, so "log out" really logs you out)
            let callback = try await session.authenticate(
                using: pageURL,
                callbackURLScheme: Self.callbackScheme,
                preferredBrowserSession: .ephemeral
            )

            //4. read ?code=...&state=... off the link and make sure it's the reply to OUR request
            let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard items.first(where: { $0.name == "state" })?.value == state else {
                errorMessage = "Login reply didn't match. Please try again."
                return
            }
            guard let code = items.first(where: { $0.name == "code" })?.value else {
                errorMessage = items.first(where: { $0.name == "error_description" })?.value ?? "Login was cancelled"
                return
            }

            //5. trade the code for our session token
            let result: TokenResponse = try await APIClient.post("auth/token", body: TokenRequest(code: code))
            KeychainStore.saveToken(result.token)
            APIClient.authToken = result.token
            userID = result.user_id
            email = result.email
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            //they closed the login sheet, nothing to complain about
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - logout

    func logout() async {
        //tell the backend to blocklist this token (if it fails, we still forget it on this device)
        let _: MessageResponse? = try? await APIClient.post("auth/logout", body: [String: String]())
        signOutLocally()
    }

    private func signOutLocally() {
        KeychainStore.deleteToken()
        APIClient.authToken = nil
        userID = nil
        email = nil
    }
}
