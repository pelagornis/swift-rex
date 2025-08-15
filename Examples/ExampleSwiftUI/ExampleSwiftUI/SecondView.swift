import SwiftUI
import Rex
import Combine

struct SecondView: View {
    @ObservedObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var eventLog: [String] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Second Page")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Waiting for events from first page...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Stats from Store
                VStack(spacing: 12) {
                    Text("Chat Stats")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(store.state.messages.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Messages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(store.state.onlineUsers.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Online Users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text(store.state.currentUser.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Current User")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Send Message to First Page") {
                        sendMessageToFirstPage()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Add User from Second Page") {
                        addUserFromSecondPage()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Trigger System Event") {
                        triggerSystemEvent()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                
                // Event Log
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Log")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(eventLog, id: \.self) { log in
                                Text(log)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Back") {
                        goBack()
                    }
                }
            }
        }
        .onAppear {
            setupEventBus()
            addLog("🚀 SecondView appeared")
        }
    }
    
    // MARK: - Event Bus Setup
    private func setupEventBus() {
        Task { @MainActor in
            // Subscribe to all events
            store.getEventBus().subscribe { event in
                addLog("📱 All Event: \(type(of: event))")
            }
            .store(in: &cancellables)
            
            // Subscribe to chat events
            store.getEventBus().subscribe(to: ChatEvent.self) { event in
                addLog("💬 Chat Event: \(event.type) from \(event.sender)")
            }
            .store(in: &cancellables)
            
            // Subscribe to user events
            store.getEventBus().subscribe(to: UserEvent.self) { event in
                addLog("👤 User Event: \(event.action) by \(event.username)")
            }
            .store(in: &cancellables)
            
            // Subscribe to system events
            store.getEventBus().subscribe(to: SystemEvent.self) { event in
                addLog("⚙️ System Event: \(event.event)")
            }
            .store(in: &cancellables)
            
            addLog("🚀 EventBus subscriptions setup complete")
        }
    }
    
    // MARK: - Actions
    private func sendMessageToFirstPage() {
        addLog("📤 Sending message to first page")
        
        Task { @MainActor in
            store.getEventBus().publishChatEvent(
                type: "message_from_second",
                message: "Hello from Second Page!",
                sender: "SecondView"
            )
            addLog("📤 ChatEvent published: message_from_second")
        }
    }
    
    private func addUserFromSecondPage() {
        addLog("👤 Adding user from second page")
        
        Task { @MainActor in
            store.getEventBus().publishUserEvent(
                action: "user_added",
                username: "SecondPageUser",
                data: ["source": "second_page"]
            )
            addLog("📤 UserEvent published: user_added")
        }
    }
    
    private func triggerSystemEvent() {
        addLog("⚙️ Triggering system event")
        
        Task { @MainActor in
            store.getEventBus().publishSystemEvent(
                event: "system_notification",
                details: ["message": "System event from second page", "timestamp": Date().description]
            )
            addLog("📤 SystemEvent published: system_notification")
        }
    }
    
    private func goBack() {
        addLog("🔙 Going back to first page")
        
        Task { @MainActor in
            store.getEventBus().publishSystemEvent(
                event: "navigation",
                details: ["action": "back_to_first", "from": "second_page"]
            )
        }
        
        dismiss()
    }
    
    // MARK: - Helper Methods
    private func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logEntry = "[\(timestamp)] \(message)"
        eventLog.append(logEntry)
        
        // Keep only last 50 logs
        if eventLog.count > 50 {
            eventLog.removeFirst()
        }
    }
}
