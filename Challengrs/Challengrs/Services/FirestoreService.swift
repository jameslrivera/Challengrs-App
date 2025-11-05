//
//  FirestoreService.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init(){}

    func createChallenge(_ challenge: Challenge, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            var ch = challenge
            // Ensure inviteCode exists
            if ch.inviteCode.isEmpty {
                ch.inviteCode = UUID().uuidString.prefix(6).uppercased()
            }
            let ref = try db.collection("challenges").addDocument(from: ch)
            completion(.success(ref.documentID))
        } catch {
            completion(.failure(error))
        }
    }

    func fetchChallenges(for userId: String, completion: @escaping (Result<[Challenge], Error>) -> Void) {
        db.collection("challenges")
            .whereField("participants", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let e = error { completion(.failure(e)); return }
                let docs = snapshot?.documents ?? []
                let challenges = docs.compactMap { try? $0.data(as: Challenge.self) }
                completion(.success(challenges))
            }
    }

    func joinChallengeByInviteCode(_ code: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let q = db.collection("challenges").whereField("inviteCode", isEqualTo: code.uppercased()).limit(to: 1)
        q.getDocuments { snapshot, error in
            if let e = error { completion(.failure(e)); return }
            guard let doc = snapshot?.documents.first else {
                completion(.failure(NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invite not found"])))
                return
            }
            let ref = doc.reference
            ref.updateData(["participants": FieldValue.arrayUnion([userId])]) { err in
                if let e = err { completion(.failure(e)); return }
                completion(.success(()))
            }
        }
    }
}
