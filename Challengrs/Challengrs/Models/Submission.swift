//
//  Submission.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseFirestoreSwift

struct Submission: Identifiable, Codable {
    var id: String?
    var challengeId: String
    var userId: String
    var photoURL: String
    var createdAt: Date?
    var approvedBy: [String]?
    var rejectedBy: [String]?
}
