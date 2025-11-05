//
//  SplashContainerView.swift
//  Challengrs
//
//  Created by James Rivera on 11/5/25.
//

import SwiftUI

struct SplashContainerView: View {
    @State private var showAuth = false

    var body: some View {
        ZStack {
            SplashView()
            VStack {
                Spacer()
                Button(action: { showAuth = true }) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
                .sheet(isPresented: $showAuth) {
                    AuthView()
                }
            }
        }
    }
}

