import Foundation

class ListViewModel: ObservableObject {
    @Published var items: [String] = []
    
    init() {
        // Sample data
        self.items = [
            "Item 1",
            "Item 2",
            "Item 3",
            "Item 4",
            "Item 5"
        ]
    }
}
