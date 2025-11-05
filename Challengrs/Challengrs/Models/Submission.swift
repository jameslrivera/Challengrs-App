//
//  Submission.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseFirestoreSwift

struct Submission: Identifiable, Codable {
    @DocumentID var id: String?
    var challengeID: String
    var userID: String
    var date: Date
    var photoURL: String
    var approvals: [String] // list of userIDs who approved

    init(id: String? = nil,
         challengeID: String,
         userID: String,
         date: Date = Date(),
         photoURL: String,
         approvals: [String] = []) {
        self.id = id
        self.challengeID = challengeID
        self.userID = userID
        self.date = date
        self.photoURL = photoURL
        self.approvals = approvals
    }
}

