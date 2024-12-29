import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var ratingManager = RatingManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to Herbi",
            description: "Your personal plant identification and care companion.",
            imageName: "leaf.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Identify Plants",
            description: "Take a photo or choose from your gallery to identify any plant.",
            imageName: "camera.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Track Your Garden",
            description: "Save your discoveries and keep track of your growing garden.",
            imageName: "heart.fill",
            color: .pink
        ),
        OnboardingPage(
            title: "Care Reminders",
            description: "Get notified when it's time to water your plants.",
            imageName: "bell.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "Help Our Team",
            description: "Thank you for helping us improve! Your ratings make a big difference.",
            imageName: "star.fill",
            color: .yellow
        )
    ]
    
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .onChange(of: currentPage) { newPage in
                if newPage == 4 {
                    Task {
                        await ratingManager.requestReview()
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                Spacer()
                
                if currentPage == pages.count - 1 {
                    Button {
                        hasSeenOnboarding = true
                        dismiss()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                } else {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundStyle(page.color)

            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview {
    OnboardingView()
} 
