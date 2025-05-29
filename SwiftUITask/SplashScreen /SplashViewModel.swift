import Foundation

class SplashViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var shouldNavigateToList = false
    
    init() {
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            self.shouldNavigateToList = true
        }
    }
}
