import SwiftUI

struct GeminiLogo: View {
    var size: CGFloat = 512
    
    var body: some View {
        ZStack {
            // Background Gradient (Deep Space/AI feel)
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.15, blue: 0.4), // Deep Blue
                            Color(red: 0.05, green: 0.05, blue: 0.15) // Near Black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle Glowing Halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .blur(radius: size * 0.05)
            
            // Central Star/Gemini Symbol
            ZStack {
                // Outer Glow for the symbol
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.45))
                    .foregroundColor(Color.blue.opacity(0.5))
                    .blur(radius: size * 0.02)
                
                // Main Symbol
                Image(systemName: "sparkles")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .frame(width: size, height: size)
    }
}
