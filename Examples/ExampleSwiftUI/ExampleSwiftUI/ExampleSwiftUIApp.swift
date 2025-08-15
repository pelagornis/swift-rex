import SwiftUI
import Rex

@main
struct ExampleSwiftUIApp: App {

    let store = Store(
        initialState: AppState(),
        reducer: AppReducer()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(store: AppStore(store: store))
        }
    }
}
