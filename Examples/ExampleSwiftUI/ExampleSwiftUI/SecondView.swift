import SwiftUI
import Rex

struct SecondView: View {
    @ObservedObject var environment: AppEnvironment

    private var store: ObservableStore<AppReducer> { environment.observableStore }
    private var graphStore: GraphStore<AppReducer> { environment.graphStore }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Second Page")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Graph node: second (mounted)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            VStack(spacing: 12) {
                Text("Chat Stats")
                    .font(.headline)

                HStack(spacing: 20) {
                    statBlock(title: "Messages", value: "\(store.state.messages.count)")
                    statBlock(title: "Online", value: "\(store.state.onlineUsers.count)")
                    statBlock(title: "User", value: store.state.currentUser.name)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            VStack(spacing: 12) {
                Button("Send Message to Chat") {
                    store.send(.delegate(.messageToChat("Hello from Second Page!")))
                }
                .buttonStyle(.borderedProminent)

                Button("Add User") {
                    store.send(.delegate(.addUser(name: "SecondPageUser")))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("System Notification") {
                    store.send(.delegate(.systemNotification("System event from second page")))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            ActivityLogView(logs: store.state.activityLog)

            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Back") {
                    store.send(.delegate(.navigatedBack))
                    graphStore.pop()
                }
            }
        }
        .onAppear {
            store.send(.logActivity("🚀 SecondView appeared"))
        }
        .onDisappear {
            store.send(.logActivity("👋 SecondView disappeared (unmounted)"))
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
