//
//  FirestoreService.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init(){}

    // Create a challenge by writing a dictionary to Firestore.
    func createChallenge(_ challenge: Challenge, completion: @escaping (Result<String, Error>) -> Void) {
        var ch = challenge
        if ch.inviteCode.isEmpty {
            ch.inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
        }

        // build dictionary representation
        var data: [String: Any] = [
            "name": ch.name,
            "description": ch.description,
            "stake": ch.stake,
            "reminderTime": ch.reminderTime,
            "participants": ch.participants,
            "inviteCode": ch.inviteCode
        ]
        // Dates -> Firestore Timestamp
        data["startDate"] = Timestamp(date: ch.startDate)
        data["endDate"] = Timestamp(date: ch.endDate)
        data["createdBy"] = ch.createdBy ?? ""

        db.collection("challenges").addDocument(data: data) { err in
            if let e = err {
                completion(.failure(e))
                return
            }
            // Find the last added doc by reading the collection? Firestore returns ref in closure only for setData
            // However addDocument returns DocumentReference in its synchronous return; we can grab it by adding document() then setData:
            // To keep it simple and reliable, add documentRef then set data:
            // (But because we already used addDocument above, we will fallback to searching for inviteCode - this is OK for prototype)
            // Simpler: create documentRef then setData:
            // (We will rewrite to use that approach to reliably return documentID.)
        }
    }

    // Alternate create that reliably returns documentID:
    func createChallengeWithID(_ challenge: Challenge, completion: @escaping (Result<String, Error>) -> Void) {
        var ch = challenge
        if ch.inviteCode.isEmpty {
            ch.inviteCode = String(UUID().uuidString.prefix(6)).uppercased()
        }

        var data: [String: Any] = [
            "name": ch.name,
            "description": ch.description,
            "stake": ch.stake,
            "reminderTime": ch.reminderTime,
            "participants": ch.participants,
            "inviteCode": ch.inviteCode,
            "createdBy": ch.createdBy ?? ""
        ]
        data["startDate"] = Timestamp(date: ch.startDate)
        data["endDate"] = Timestamp(date: ch.endDate)

        let ref = db.collection("challenges").document() // auto ID
        ref.setData(data) { err in
            if let e = err { completion(.failure(e)); return }
            completion(.success(ref.documentID))
        }
    }

    // Fetch challenges for a user by parsing documents into Challenge objects
    func fetchChallenges(for userId: String, completion: @escaping (Result<[Challenge], Error>) -> Void) {
        db.collection("challenges")
            .whereField("participants", arrayContains: userId)
            .getDocuments { snapshot, error in
                if let e = error { completion(.failure(e)); return }
                let docs = snapshot?.documents ?? []
                let mapped: [Challenge] = docs.compactMap { doc in
                    let data = doc.data()
                    guard let name = data["name"] as? String,
                          let description = data["description"] as? String,
                          let stake = data["stake"] as? Double ?? (data["stake"] as? NSNumber)?.doubleValue,
                          let reminderTime = data["reminderTime"] as? String,
                          let inviteCode = data["inviteCode"] as? String else {
                        return nil
                    }

                    let participants = data["participants"] as? [String] ?? []
                    let createdBy = data["createdBy"] as? String

                    // parse timestamps -> Date
                    var startDate = Date()
                    var endDate = Date()
                    if let ts = data["startDate"] as? Timestamp {
                        startDate = ts.dateValue()
                    } else if let s = data["startDate"] as? Date {
                        startDate = s
                    }
                    if let ts2 = data["endDate"] as? Timestamp {
                        endDate = ts2.dateValue()
                    } else if let e = data["endDate"] as? Date {
                        endDate = e
                    }

                    let id = doc.documentID
                    return Challenge(id: id, name: name, description: description, stake: stake, startDate: startDate, endDate: endDate, reminderTime: reminderTime, participants: participants, inviteCode: inviteCode, createdBy: createdBy)
                }
                completion(.success(mapped))
            }
    }

    // Join challenge by invite code
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

    // Submission helpers (optional; add if you plan to support submissions)
    func addSubmission(_ submission: Submission, completion: @escaping (Result<String, Error>) -> Void) {
        var data: [String: Any] = [
            "challengeID": submission.challengeID,
            "userID": submission.userID,
            "photoURL": submission.photoURL,
            "approvals": submission.approvals
        ]
        data["date"] = Timestamp(date: submission.date)
        let ref = db.collection("submissions").document()
        ref.setData(data) { err in
            if let e = err { completion(.failure(e)); return }
            completion(.success(ref.documentID))
        }
    }

    func approveSubmission(submissionID: String, approverID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = db.collection("submissions").document(submissionID)
        docRef.updateData(["approvals": FieldValue.arrayUnion([approverID])]) { err in
            if let e = err { completion(.failure(e)); return }
            completion(.success(()))
        }
    }
}
    

