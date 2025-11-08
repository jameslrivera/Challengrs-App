//
//  Challenge.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseFirestoreSwift

enum Frequency: String, Codable {
    case daily, weekly, custom
}

struct Challenge: Identifiable, Codable {
    @DocumentID var id: String?

    var name: String
    var description: String
    var stake: Double

    var startDate: Date
    var endDate: Date
    var reminderTime: String = "20:00"
    var participants: [String] = []
    var inviteCode: String = ""
    var createdBy: String?

    // optional extra fields
    var frequency: Frequency? = nil
    var requiredPerWeek: Int? = nil
    var daysOfWeek: [Int]? = nil
    var createdAt: Date? = nil

    init(id: String? = nil,
         name: String,
         description: String,
         stake: Double,
         startDate: Date,
         endDate: Date,
         reminderTime: String = "20:00",
         participants: [String] = [],
         inviteCode: String = "",
         createdBy: String? = nil,
         frequency: Frequency? = nil,
         requiredPerWeek: Int? = nil,
         daysOfWeek: [Int]? = nil,
         createdAt: Date? = nil) {
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
        self.frequency = frequency
        self.requiredPerWeek = requiredPerWeek
        self.daysOfWeek = daysOfWeek
        self.createdAt = createdAt
    }
}
