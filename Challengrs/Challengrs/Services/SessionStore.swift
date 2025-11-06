//
//  SessionStore.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class SessionStore: ObservableObject {
    static let shared = SessionStore()

    @Published var currentUser: SimpleUser? = nil
    private var handle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {
        listen()
    }

    // MARK: - Auth state listener
    private func listen() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let u = user {
                self.fetchUser(uid: u.uid) { result in
                    switch result {
                    case .success(let sUser):
                        DispatchQueue.main.async { self.currentUser = sUser }
                    case .failure:
                        // fallback to minimal user from Auth
                        let fallback = SimpleUser(
                            id: u.uid,
                            email: u.email ?? "",
                            firstName: u.displayName ?? "",
                            lastName: "",
                            photoURL: u.photoURL?.absoluteString,
                            createdAt: Date()
                        )
                        DispatchQueue.main.async { self.currentUser = fallback }
                    }
                }
            } else {
                DispatchQueue.main.async { self.currentUser = nil }
            }
        }
    }

    // MARK: - Sign up / Sign in / Sign out
    func signUp(email: String, password: String, firstName: String, lastName: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let err = error { DispatchQueue.main.async { completion(err) }; return }
            guard let user = result?.user else {
                DispatchQueue.main.async { completion(NSError(domain: "SessionStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])) }
                return
            }

            // Update Auth profile displayName and then create user doc
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = firstName
            if let url = user.photoURL { changeRequest.photoURL = url } // optional

            changeRequest.commitChanges { [weak self] changeErr in
                // ignore profile change error but log it
                if let ce = changeErr { print("Profile commit error:", ce.localizedDescription) }

                // send verification (best-effort)
                user.sendEmailVerification(completion: nil)

                // create Firestore profile doc (only after commit completes)
                self?.createUserDoc(uid: user.uid, email: email, firstName: firstName, lastName: lastName) { createErr in
                    DispatchQueue.main.async { completion(createErr) }
                }
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    func signOut() -> Error? {
        do {
            try Auth.auth().signOut()
            return nil
        } catch {
            return error
        }
    }

    // MARK: - Password reset / email verification helpers
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            DispatchQueue.main.async { completion(err) }
        }
    }

    func resendEmailVerification(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            DispatchQueue.main.async { completion(NSError(domain: "SessionStore", code: 401, userInfo: [NSLocalizedDescriptionKey: "No signed in user"])) }
            return
        }
        user.sendEmailVerification { err in
            DispatchQueue.main.async { completion(err) }
        }
    }

    func isEmailVerified() -> Bool {
        return Auth.auth().currentUser?.isEmailVerified ?? false
    }

    func refreshCurrentUser(completion: @escaping (Error?) -> Void = { _ in }) {
        Auth.auth().currentUser?.reload(completion: { err in
            DispatchQueue.main.async { completion(err) }
        })
    }

    // MARK: - Firestore profile helpers
    private func createUserDoc(uid: String, email: String, firstName: String, lastName: String, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection("users").document(uid)
        let data: [String: Any] = [
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": FieldValue.serverTimestamp()
        ]
        docRef.setData(data) { error in
            DispatchQueue.main.async { completion(error) }
        }
    }

    private func fetchUser(uid: String, completion: @escaping (Result<SimpleUser, Error>) -> Void) {
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { snap, error in
            if let e = error { DispatchQueue.main.async { completion(.failure(e)) }; return }
            guard let doc = snap, doc.exists, let data = doc.data() else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "SessionStore", code: 404, userInfo: [NSLocalizedDescriptionKey: "User doc not found"])))
                }
                return
            }
            let email = data["email"] as? String ?? ""
            let first = data["firstName"] as? String ?? ""
            let last = data["lastName"] as? String ?? ""
            var createdAtDate: Date? = nil
            if let ts = data["createdAt"] as? Timestamp { createdAtDate = ts.dateValue() }
            let s = SimpleUser(id: uid, email: email, firstName: first, lastName: last, photoURL: data["photoURL"] as? String, createdAt: createdAtDate)
            DispatchQueue.main.async { completion(.success(s)) }
        }
    }

    deinit {
        if let h = handle { Auth.auth().removeStateDidChangeListener(h) }
    }
}

// MARK: - Profile updates, password change, account deletion
extension SessionStore {

    /// Update the user's profile (first/last name, and update displayName in Auth & user doc).
    /// Calls completion on main thread.
    func updateProfile(firstName: String, lastName: String, photoURL: String? = nil, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            DispatchQueue.main.async { completion(NSError(domain: "SessionStore", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])) }
            return
        }
        // Update Auth profile first, then write Firestore doc when commit completes.
        let change = user.createProfileChangeRequest()
        change.displayName = firstName
        if let url = photoURL { change.photoURL = URL(string: url) }

        change.commitChanges { [weak self] changeErr in
            if let err = changeErr {
                print("Warning: commitChanges error:", err.localizedDescription)
            }
            guard let self = self else {
                DispatchQueue.main.async { completion(NSError(domain: "SessionStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "Session invalid"])) }; return
            }

            let docRef = self.db.collection("users").document(user.uid)
            var data: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName
            ]
            if let url = photoURL { data["photoURL"] = url }

            docRef.setData(data, merge: true) { err in
                if let e = err {
                    DispatchQueue.main.async { completion(e) }
                    return
                }
                // refresh local currentUser from Firestore to reflect changes
                self.fetchUser(uid: user.uid) { _ in
                    DispatchQueue.main.async { completion(nil) }
                }
            }
        }
    }

    /// Change password — reauthenticate using currentPassword then update password.
    /// completion called on main thread.
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            DispatchQueue.main.async { completion(NSError(domain: "SessionStore", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])) }
            return
        }

        let cred = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: cred) { _, err in
            if let e = err { DispatchQueue.main.async { completion(e) }; return }
            user.updatePassword(to: newPassword) { err2 in
                DispatchQueue.main.async { completion(err2) }
            }
        }
    }

    /// Delete account: reauth with current password, delete Firestore doc and attempt best-effort Storage cleanup.
    /// For full cleanup prefer a Cloud Function using admin privileges.
    func deleteAccount(currentPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            DispatchQueue.main.async {
                completion(NSError(domain: "SessionStore", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in"]))
            }
            return
        }

        let uid = user.uid
        print("[SessionStore] deleteAccount: starting for uid=\(uid)")

        let cred = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: cred) { [weak self] _, reauthErr in
            guard let self = self else {
                DispatchQueue.main.async { completion(NSError(domain: "SessionStore", code: -2, userInfo: nil)) }
                return
            }
            if let reauthErr = reauthErr {
                print("[SessionStore] reauth failed:", reauthErr.localizedDescription)
                DispatchQueue.main.async { completion(reauthErr) }
                return
            }
            print("[SessionStore] reauth succeeded for uid=\(uid)")

            var firstError: Error? = nil

            // 1) delete Firestore user doc
            let userDoc = self.db.collection("users").document(uid)
            userDoc.delete { userDocErr in
                if let e = userDocErr {
                    print("[SessionStore] warning: failed to delete user doc:", e.localizedDescription)
                    if firstError == nil { firstError = e }
                } else {
                    print("[SessionStore] user doc deleted")
                }

                // 2) attempt to remove avatar and user files (best-effort)
                let avatarRef = self.storage.reference().child("avatars/\(uid).jpg")
                avatarRef.delete { avatarErr in
                    if let aerr = avatarErr {
                        print("[SessionStore] avatar delete warning:", aerr.localizedDescription)
                        if firstError == nil { firstError = aerr }
                    } else {
                        print("[SessionStore] avatar deleted")
                    }

                    // Attempt to delete user folder contents (if any)
                    let userFolderRef = self.storage.reference().child("users/\(uid)")
                    userFolderRef.listAll { listResult, listErr in
                        if let listErr = listErr {
                            print("[SessionStore] listAll warning:", listErr.localizedDescription)
                            if firstError == nil { firstError = listErr }
                        } else {
                            // delete items (best-effort)
                            for item in listResult.items {
                                item.delete { delErr in
                                    if let d = delErr {
                                        print("[SessionStore] item delete warning:", d.localizedDescription)
                                        if firstError == nil { firstError = d }
                                    } else {
                                        print("[SessionStore] deleted storage item: \(item.fullPath)")
                                    }
                                }
                            }
                            // delete subfolder items if any
                            for prefix in listResult.prefixes {
                                prefix.listAll { subRes, subErr in
                                    if let subErr = subErr {
                                        print("[SessionStore] subfolder list warning:", subErr.localizedDescription)
                                        if firstError == nil { firstError = subErr }
                                    } else {
                                        for it in subRes.items {
                                            it.delete { de in
                                                if let de = de { print("[SessionStore] sub-item delete warning:", de.localizedDescription); if firstError == nil { firstError = de } }
                                                else { print("[SessionStore] deleted sub-item: \(it.fullPath)") }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3) Finally attempt to delete the Firebase Auth user
                        user.delete { authDelErr in
                            if let authDelErr = authDelErr {
                                print("[SessionStore] user.delete() failed:", authDelErr.localizedDescription)
                                // If it's a 'recent login' error, surface it literally
                                if firstError == nil { firstError = authDelErr }
                                DispatchQueue.main.async { completion(firstError ?? authDelErr) }
                            } else {
                                print("[SessionStore] Firebase Auth user deleted successfully")
                                DispatchQueue.main.async { completion(firstError) } // firstError may be nil (ideal)
                            }
                        }
                    } // end listAll
                } // end avatar delete
            } // end userDoc delete
        } // end reauth
    }
}
