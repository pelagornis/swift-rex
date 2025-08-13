import SwiftUI
import Rex

struct ContentView: View {
    @StateObject var store: AppStore

    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(store.state.count)")
            if store.state.isLoading { ProgressView() }

            HStack {
                Button("Increment") { store.send(.increment) }
                Button("Decrement") { store.send(.decrement) }
            }

            Button("Reset with Just") { store.send(.reset) }
            Button("Load") { store.send(.loadFromServer) }
        }
        .padding()
    }
}
