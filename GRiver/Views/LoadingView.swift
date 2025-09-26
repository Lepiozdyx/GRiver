import SwiftUI

struct LoadingView: View {
    
    @State private var animateLogo = false
    @State private var loading: CGFloat = 0
    
    var body: some View {
        ZStack {
            Image(.loadingScreen)
                .resizable()
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image(.loadLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .scaleEffect(animateLogo ? 1.01 : 0.98)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: animateLogo
                    )
                
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 300, maxHeight: 15)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(.black)
                            .frame(width: 297 * loading, height: 13)
                            .padding(.horizontal, 1)
                    }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5)) {
                loading = 1
            }
            animateLogo.toggle()
        }
    }
}

#Preview {
    LoadingView()
}
