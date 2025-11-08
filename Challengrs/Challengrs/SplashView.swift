//
//  SplashView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 160, height: 160)
                    Image(systemName: "checkmark.seal.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78, height: 78)
                        .foregroundColor(.blue)
                        .scaleEffect(animate ? 1.05 : 0.95)
                }
                Text("Challengrs")
                    .font(.system(size: 28, weight: .semibold))
                Text("Are you up for the Challenge?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
    }
}
