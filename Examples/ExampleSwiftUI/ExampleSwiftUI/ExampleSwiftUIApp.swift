import SwiftUI
import Rex

@main
struct ExampleSwiftUIApp: App {

    let store = Store(
        initialState: AppState(),
        reducer: AppReducer()
    ) {
        LoggingMiddleware()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: AppStore(store: store))
        }
    }
}
