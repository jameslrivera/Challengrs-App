//
//  SessionStore.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published var currentUser: SimpleUser? = nil
    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    private init() {
        listen()
    }

    // Observe Firebase Auth state
    private func listen() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let u = user {
                // fetch user doc
                self.fetchUser(uid: u.uid) { result in
                    switch result {
                    case .success(let sUser):
                        DispatchQueue.main.async {
                            self.currentUser = sUser
                        }
                    case .failure:
                        // If user doc is missing, build minimal SimpleUser from auth
                        let fallback = SimpleUser(id: u.uid, email: u.email ?? "", firstName: "", lastName: "", photoURL: nil, createdAt: Date())
                        DispatchQueue.main.async {
                            self.currentUser = fallback
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                }
            }
        }
    }

    // MARK: - Public: Sign up
    /// Creates a Firebase Auth user, sets displayName, creates a Firestore user doc.
    func signUp(email: String, password: String, firstName: String, lastName: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let err = error { completion(err); return }
            guard let self = self, let user = result?.user else { completion(NSError(domain: "SessionStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])); return }

            // Update Auth profile displayName
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = firstName
            changeRequest.commitChanges { err in
                if let e = err { print("profile update error:", e.localizedDescription) }
                // send email verification
                user.sendEmailVerification { _ in /* ignore errors for now */ }
                // create user doc in Firestore
                self.createUserDoc(uid: user.uid, email: email, firstName: firstName, lastName: lastName) { err in
                    completion(err)
                }
            }
        }
    }

    // MARK: - Public: Sign in
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            completion(error)
        }
    }

    // MARK: - Public: Sign out
    func signOut() -> Error? {
        do {
            try Auth.auth().signOut()
            return nil
        } catch {
            return error
        }
    }

    // MARK: - Helpers
    private func createUserDoc(uid: String, email: String, firstName: String, lastName: String, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection("users").document(uid)
        let data: [String: Any] = [
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": FieldValue.serverTimestamp()
        ]
        docRef.setData(data) { error in
            completion(error)
        }
    }

    private func fetchUser(uid: String, completion: @escaping (Result<SimpleUser, Error>) -> Void) {
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { snap, error in
            if let e = error { completion(.failure(e)); return }
            guard let doc = snap, doc.exists, let data = doc.data() else {
                completion(.failure(NSError(domain: "SessionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "User doc not found"])))
                return
            }
            let email = data["email"] as? String ?? ""
            let first = data["firstName"] as? String ?? ""
            let last = data["lastName"] as? String ?? ""
            var createdAtDate: Date? = nil
            if let ts = data["createdAt"] as? Timestamp { createdAtDate = ts.dateValue() }
            let s = SimpleUser(id: uid, email: email, firstName: first, lastName: last, photoURL: data["photoURL"] as? String, createdAt: createdAtDate)
            completion(.success(s))
        }
    }

    deinit {
        if let h = handle {
            Auth.auth().removeStateDidChangeListener(h)
        }
    }
}
