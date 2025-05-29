import SwiftUI

struct ListView: View {
    @StateObject private var viewModel = ListViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.items, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("Items List")
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
    }
}
