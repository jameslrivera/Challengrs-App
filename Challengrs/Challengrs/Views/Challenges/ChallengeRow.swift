//
//  ChallengeRow.swift
//  Challengrs
//
//  Created by James Rivera on 11/6/25.
//

import Foundation
import SwiftUI


import SwiftUI

struct ChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(challenge.name)
                .font(.headline)
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Stake: $\(challenge.stake, specifier: "%.2f")")
                Spacer()
                Text("\(challenge.participants.count) participants")
            }
            .font(.footnote)
            
            Text("From \(challenge.startDate.formatted(date: .abbreviated, time: .omitted)) to \(challenge.endDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
