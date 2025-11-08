//
//  FirestoreService.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//


import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // Create challenge (returns document ID)
    func createChallenge(_ challenge: Challenge, completion: @escaping (Result<String, Error>) -> Void) {
        var ch = challenge
        if ch.inviteCode.isEmpty { ch.inviteCode = String(UUID().uuidString.prefix(6)).uppercased() }

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
        data["createdAt"] = FieldValue.serverTimestamp()

        let ref = db.collection("challenges").document()
        ref.setData(data) { err in
            DispatchQueue.main.async {
                if let e = err { completion(.failure(e)); return }
                completion(.success(ref.documentID))
            }
        }
    }

    // Fetch challenges for user (no explicit QuerySnapshot type)
    func fetchChallenges(for userId: String, completion: @escaping (Result<[Challenge], Error>) -> Void) {
        db.collection("challenges")
            .whereField("participants", arrayContains: userId)
            .getDocuments(source: .default) { snapshot, error in
                if let e = error {
                    DispatchQueue.main.async { completion(.failure(e)) }
                    return
                }
                guard let docs = snapshot?.documents else {
                    DispatchQueue.main.async { completion(.success([])) }
                    return
                }
               
                var results: [Challenge] = []
                for doc in docs {
                    let data = doc.data()
                    guard let name = data["name"] as? String else { continue }
                    let description = data["description"] as? String ?? ""
                    let stake: Double
                    if let s = data["stake"] as? Double { stake = s }
                    else if let n = data["stake"] as? NSNumber { stake = n.doubleValue }
                    else { stake = 0.0 }
                   
                    let reminderTime = data["reminderTime"] as? String ?? "20:00"
                    let inviteCode = data["inviteCode"] as? String ?? ""
                    let participants = data["participants"] as? [String] ?? []
                    let createdBy = data["createdBy"] as? String
                   
                    var startDate = Date()
                    var endDate = Date()
                    if let ts = data["startDate"] as? Timestamp { startDate = ts.dateValue() }
                    else if let d = data["startDate"] as? Date { startDate = d }
                    if let ts2 = data["endDate"] as? Timestamp { endDate = ts2.dateValue() }
                    else if let d2 = data["endDate"] as? Date { endDate = d2 }
                   
                    var createdAt: Date? = nil
                    if let cat = data["createdAt"] as? Timestamp { createdAt = cat.dateValue() }
                    else if let cad = data["createdAt"] as? Date { createdAt = cad }
                   
                    let challenge = Challenge(id: doc.documentID,
                                              name: name,
                                              description: description,
                                              stake: stake,
                                              startDate: startDate,
                                              endDate: endDate,
                                              reminderTime: reminderTime,
                                              participants: participants,
                                              inviteCode: inviteCode,
                                              createdBy: createdBy,
                                              createdAt: createdAt)
                    results.append(challenge)
                }
           
                DispatchQueue.main.async { completion(.success(results)) }
            }
    }

    // Join by invite
    func joinChallengeByInviteCode(_ code: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("challenges")
            .whereField("inviteCode", isEqualTo: code.uppercased())
            .limit(to: 1)
            .getDocuments(source: .default) { snapshot, error in
                if let e = error {
                    DispatchQueue.main.async { completion(.failure(e)) }
                    return
                }
                guard let doc = snapshot?.documents.first else {
                    DispatchQueue.main.async { completion(.failure(NSError(domain: "FirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invite not found"]))) }
                    return
                }
                doc.reference.updateData(["participants": FieldValue.arrayUnion([userId])]) { err in
                    DispatchQueue.main.async {
                        if let e = err { completion(.failure(e)); return }
                        completion(.success(()))
                    }
                }
            }
    }

    // Add submission (writes submission doc)
    func addSubmission(challengeId: String, userId: String, photoURL: String, date: Date = Date(), approvals: [String] = [], completion: @escaping (Result<String, Error>) -> Void) {
        var data: [String: Any] = [
            "challengeId": challengeId,
            "userId": userId,
            "photoURL": photoURL,
            "approvals": approvals
        ]
        data["createdAt"] = Timestamp(date: date)

        let ref = db.collection("submissions").document()
        ref.setData(data) { err in
            DispatchQueue.main.async {
                if let e = err { completion(.failure(e)); return }
                completion(.success(ref.documentID))
            }
        }
    }

    // Approve submission
    func approveSubmission(submissionID: String, approverID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = db.collection("submissions").document(submissionID)
        docRef.updateData(["approvals": FieldValue.arrayUnion([approverID])]) { err in
            DispatchQueue.main.async {
                if let e = err { completion(.failure(e)); return }
                completion(.success(()))
            }
        }
    }

    // Fetch submissions for a user + challenge (no explicit snapshot type)
    func fetchSubmissions(challengeId: String, userId: String, from start: Date? = nil, to end: Date? = nil, completion: @escaping (Result<[(id: String, dict: [String: Any])], Error>) -> Void) {
        var q: Query = db.collection("submissions")
            .whereField("challengeId", isEqualTo: challengeId)
            .whereField("userId", isEqualTo: userId)

        if let start = start { q = q.whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: start)) }
        if let end = end { q = q.whereField("createdAt", isLessThanOrEqualTo: Timestamp(date: end)) }

        q.getDocuments(source: .default) { snapshot, error in
            if let e = error {
                DispatchQueue.main.async { completion(.failure(e)) }
                return
            }
            guard let docs = snapshot?.documents else {
                DispatchQueue.main.async { completion(.success([])) }
                return
            }

            var arr: [(id: String, dict: [String: Any])] = []
            for d in docs { arr.append((id: d.documentID, dict: d.data())) }
            DispatchQueue.main.async { completion(.success(arr)) }
        }
    }

    // Upload image helper
    func uploadSubmissionImage(imageData: Data, challengeId: String, userId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let path = "submissions/\(challengeId)/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        meta.customMetadata = ["userID": userId]

        ref.putData(imageData, metadata: meta) { _, err in
            if let e = err {
                DispatchQueue.main.async { completion(.failure(e)) }
                return
            }
            ref.downloadURL { url, dlErr in
                DispatchQueue.main.async {
                    if let e = dlErr { completion(.failure(e)); return }
                    guard let url = url else { completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing download URL"]))); return }
                    completion(.success(url))
                }
            }
        }
    }
    
    // New: Update participant config (saves to subcollection)
    func updateParticipantConfig(challengeId: String, config: ParticipantConfig, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = db.collection("challenges").document(challengeId).collection("participant_configs").document(config.userId)
        
        do {
            try ref.setData(from: config) { err in
                DispatchQueue.main.async {
                    if let e = err { completion(.failure(e)); return }
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }
    
    // New: Fetch participant config for a user in a challenge
    func fetchParticipantConfig(challengeId: String, userId: String, completion: @escaping (Result<ParticipantConfig?, Error>) -> Void) {
        let ref = db.collection("challenges").document(challengeId).collection("participant_configs").document(userId)
        
        ref.getDocument { snapshot, error in
            if let e = error {
                DispatchQueue.main.async { completion(.failure(e)) }
                return
            }
            do {
                let config = try snapshot?.data(as: ParticipantConfig.self)
                DispatchQueue.main.async { completion(.success(config)) }
            } catch let decodeError {
                DispatchQueue.main.async { completion(.failure(decodeError)) }
            }
        }
    }
}
