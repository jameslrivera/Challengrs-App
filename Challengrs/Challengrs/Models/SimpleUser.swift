//
//  SimpleUser.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import Foundation

struct SimpleUser: Identifiable, Codable {
    var id: String
    var email: String
    var firstName: String
    var lastName: String
    var displayName: String { firstName } 
    var photoURL: String?
    var createdAt: Date?
}
