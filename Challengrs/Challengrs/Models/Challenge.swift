//
//  Challenge.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation
import FirebaseFirestoreSwift


enum Frequency: String, Codable {
    case daily
    case weekly
    case fiveTimesAWeek = "custom"  // Maps to 5x/week
}

struct Challenge: Identifiable, Codable {
    @DocumentID var id: String?

    var name: String
    var description: String
    var stake: Double

    var startDate: Date
    var endDate: Date  // Auto-set to startDate + 30 days
    var reminderTime: String = "20:00"
    var participants: [String] = []
    var inviteCode: String = ""
    var createdBy: String?

    var createdAt: Date? = nil

    init(id: String? = nil,
         name: String,
         description: String,
         stake: Double,
         startDate: Date,
         endDate: Date? = nil,  // Optional; auto-calculate if nil
         reminderTime: String = "20:00",
         participants: [String] = [],
         inviteCode: String = "",
         createdBy: String? = nil,
         createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.stake = stake
        self.startDate = startDate
        
        // Enforce 1-month timeline
        if let endDate = endDate {
            self.endDate = endDate
        } else {
            self.endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate) ?? startDate
        }
        
        self.reminderTime = reminderTime
        self.participants = participants
        self.inviteCode = inviteCode
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

