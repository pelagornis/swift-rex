import SwiftUI
import Rex

struct ContentView: View {
    @StateObject private var environment = AppEnvironment()
    @State private var messageText = ""

    private var store: ObservableStore<AppReducer> { environment.observableStore }
    private var graphStore: GraphStore<AppReducer> { environment.graphStore }

    private var isSecondPageActive: Bool {
        store.state.graph.activeNodeID?.rawValue == "second"
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSecondPageActive {
                    SecondView(environment: environment)
                } else {
                    chatMainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var chatMainContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Chat App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Online: \(store.state.onlineUsers.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Graph: \(store.state.graph.activePath.map(\.rawValue).joined(separator: " → "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            if store.state.isLoading {
                ProgressView("Loading...")
                    .padding()
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.state.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isFromCurrentUser: message.sender.id == store.state.currentUser.id
                        )
                    }

                    if store.state.isTyping {
                        TypingIndicatorView()
                    }
                }
                .padding()
            }

            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    sendMessage()
                }
                .disabled(messageText.isEmpty || store.state.isLoading)
            }
            .padding(.horizontal)

            GraphActionsDemoView(store: store)

            ActivityLogView(logs: store.state.activityLog)

            Button("Go to Second Page") {
                graphStore.push("second")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Login") {
                    store.send(.userLogin)
                }
                .disabled(store.state.isLoading)
            }
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        store.send(.sendMessage(messageText))
        messageText = ""
    }
}

struct MessageBubbleView: View {
    let message: AppState.Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack {
                    if !isFromCurrentUser {
                        Text(message.sender.avatar)
                            .font(.title2)
                    }
                    Text(message.sender.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if isFromCurrentUser {
                        Text(message.sender.avatar)
                            .font(.title2)
                    }
                }

                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isFromCurrentUser { Spacer() }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear { animationOffset = 1.0 }
    }
}

struct GraphActionsDemoView: View {
    @ObservedObject var store: ObservableStore<AppReducer>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Graph Actions Demo")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Join") { store.send(.triggerUserJoin) }
                    .buttonStyle(.bordered)
                Button("Leave") { store.send(.triggerUserLeave) }
                    .buttonStyle(.bordered)
                Button("Reply") { store.send(.triggerMessageSent) }
                    .buttonStyle(.bordered)
                Button("Typing") { store.send(.triggerTyping) }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ActivityLogView: View {
    let logs: [AppState.ActivityLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Log")
                .font(.subheadline)
                .fontWeight(.medium)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logs) { log in
                        Text(log.formatted)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
