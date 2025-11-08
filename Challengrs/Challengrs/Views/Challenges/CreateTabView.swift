//
//  CreateTabView.swift
//  Challengrs
//
//  Created by James Rivera on 11/7/25.
//

import Foundation
import SwiftUI

struct CreateTabView: View {
    @State private var showCreateForm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .foregroundColor(.blue.opacity(0.8))
                
                Text("Create a Challenge")
                    .font(.title2)
                    .bold()
                
                Text("Tap below to start a new challenge with friends.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    showCreateForm = true
                }) {
                    Text("Start a new challenge")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create")
            .sheet(isPresented: $showCreateForm) {
                CreateChallengeView()
                    .environmentObject(SessionStore.shared)  // Pass session if needed
            }
        }
    }
}
