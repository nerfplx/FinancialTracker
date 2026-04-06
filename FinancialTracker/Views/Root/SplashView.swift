import SwiftUI

struct SplashView: View {
    @Binding var showMain: Bool
    @State private var scale: CGFloat = 0.75
    @State private var pulse = false
    @State private var balanceText = "$0"
    @State private var opacity: CGFloat = 1

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.95), Color.blue.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(pulse ? 0.85 : 1)

                Text("Smart Spend Tracker")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(balanceText)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .opacity(opacity)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1
                pulse = true
            }
            animateBalance()
        }
    }

    private func animateBalance() {
        let values = ["$120", "$220", "$180", "$310", "$260"]
        for (index, value) in values.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.33) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    opacity = 0.45
                }
                balanceText = value
                withAnimation(.easeInOut(duration: 0.2)) {
                    opacity = 1
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation {
                showMain = true
            }
        }
    }
}
