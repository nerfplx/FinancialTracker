import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color.indigo.opacity(0.85) : Color.indigo)
            .cornerRadius(14)
    }
}
