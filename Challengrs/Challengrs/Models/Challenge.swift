//
//  Challenge.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseFirestoreSwift

struct Challenge: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var stake: Double
    var startDate: Date
    var endDate: Date
    var reminderTime: String // "20:00"
    var participants: [String] // user ids
    var inviteCode: String
    var createdBy: String?
    
    init(id: String? = nil,
         name: String,
         description: String,
         stake: Double,
         startDate: Date,
         endDate: Date,
         reminderTime: String = "20:00",
         participants: [String] = [],
         inviteCode: String = "",
         createdBy: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.stake = stake
        self.startDate = startDate
        self.endDate = endDate
        self.reminderTime = reminderTime
        self.participants = participants
        self.inviteCode = inviteCode
        self.createdBy = createdBy
    }
}

