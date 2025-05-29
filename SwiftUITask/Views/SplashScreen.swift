//
//  SplashScreen.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import SwiftUI

// MARK: - Splash Screen
struct SplashScreen: View {
    // MARK: - Properties
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            splashView
        }
    }
    
    private var splashView: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("SwiftUI TASK")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black.opacity(0.8))
                    .scaleEffect(size)
                    .opacity(opacity)
            }
            .onAppear(perform: startAnimations)
        }
        .onAppear(perform: setupTransition)
    }
    
    // MARK: - Animation Methods

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            size = 1.0
            opacity = 1.0
        }
    }
    
    private func setupTransition() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isActive = true
            }
        }
    }
}

#Preview {
    SplashScreen()
}
