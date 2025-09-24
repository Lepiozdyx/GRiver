import SwiftUI

struct OnboardingView: View {
    @Binding var isVisible: Bool
    @State private var currentStep = 0
    
    // Onboarding steps with explanations
    private let onboardingSteps = [
        "Welcome to the game! Your mission is to capture or destroy all points of interest on the map.",
        "Victory is achieved when all points of interest are either captured or destroyed.",
        "Defeat occurs if the alert level reaches 100% - avoid detection!",
        "Navigate the map by dragging with one finger.",
        "Zoom in/out using pinch gestures with two fingers.",
        "Tap on points of interest to interact with them.",
        "Good luck, Commander!"
    ]
    
    var body: some View {
        HStack(spacing: 10) {
            // Character image
            Image(.replicChar)
                .resizable()
                .frame(width: 100, height: 100)
            
            // Speech bubble
            // Text content
            Text(onboardingSteps[currentStep])
                .laborFont(14, color: .black)
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onTapGesture {
            nextStep()
        }
        .transition(.opacity)
        .zIndex(30)
    }
    
    private func nextStep() {
        if currentStep < onboardingSteps.count - 1 {
            currentStep += 1
        } else {
            withAnimation {
                isVisible = false
            }
        }
    }
}

#Preview {
    OnboardingView(isVisible: .constant(true))
        .preferredColorScheme(.dark)
}
