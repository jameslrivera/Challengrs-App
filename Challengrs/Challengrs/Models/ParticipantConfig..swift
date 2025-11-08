//
//  ParticipantConfig..swift
//  Challengrs
//
//  Created by James Rivera on 11/8/25.
//

import Foundation


struct ParticipantConfig: Codable {
    let userId: String
    let frequency: Frequency  // Reuse your enum: .daily, .weekly, .custom (for 5x/week)
    let goalDescription: String?  // Optional custom note, e.g., "workout pic" or "weight check"
    // Add if needed: requiredUploads: Int (e.g., 30 for daily in a month, 4 for weekly, 20 for 5x/week)
}
