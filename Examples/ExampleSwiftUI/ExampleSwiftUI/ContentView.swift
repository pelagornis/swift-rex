import SwiftUI
import Rex

struct ContentView: View {
    @StateObject var store: AppStore
    @State private var messageText = ""
    @State private var eventLog: [String] = []
    @State private var showingSecondView = false
    
    init() {
        let store = Store(
            initialState: AppState(),
            reducer: AppReducer()
        )
        self._store = StateObject(wrappedValue: AppStore(store: store))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Chat App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Online: \(store.state.onlineUsers.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Loading indicator
                if store.state.isLoading {
                    ProgressView("Loading...")
                        .padding()
                }
                
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.state.messages) { message in
                            MessageBubbleView(message: message, isFromCurrentUser: message.sender.id == store.state.currentUser.id)
                        }
                        
                        if store.state.isTyping {
                            TypingIndicatorView()
                        }
                    }
                    .padding()
                }
                .onChange(of: store.state.messages.count) { _ in
                    if let lastMessage = store.state.messages.last {
                        print("New message: \(lastMessage.text)")
                    }
                }
                
                // Message input
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .disabled(messageText.isEmpty || store.state.isLoading)
                }
                .padding(.horizontal)
                
                // Event Bus Demo
                EventBusDemoView(store: store, eventLog: $eventLog)
                
                // Navigation to second page
                Button("Go to Second Page") {
                    showingSecondView = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Login") {
                        store.send(.userLogin)
                    }
                    .disabled(store.state.isLoading)
                }
            }
        }
        .sheet(isPresented: $showingSecondView) {
            SecondView(store: store)
        }
        .onAppear {
            setupEventListeners()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        store.send(.sendMessage(messageText))
        messageText = ""
    }
    
    private func setupEventListeners() {
        Task { @MainActor in
            // Listen to all events
            store.getEventBus().subscribe { event in
                let eventString = "\(type(of: event)) at \(Date().formatted(date: .omitted, time: .standard))"
                eventLog.insert(eventString, at: 0)
                if eventLog.count > 20 {
                    eventLog.removeLast()
                }
            }
            
            // Listen to chat events
            store.getEventBus().subscribe(to: ChatEvent.self) { event in
                print("Chat Event: \(event.type) from \(event.sender)")
                
                // Handle events from second page
                if event.type == "message_from_second" {
                    eventLog.insert("💬 Message from Second Page: \(event.message)", at: 0)
                    if eventLog.count > 20 {
                        eventLog.removeLast()
                    }
                }
            }
            
            // Listen to user events
            store.getEventBus().subscribe(to: UserEvent.self) { event in
                print("User Event: \(event.action) by \(event.username)")
                
                // Handle events from second page
                if event.action == "user_added" {
                    eventLog.insert("👤 User added from Second Page: \(event.username)", at: 0)
                    if eventLog.count > 20 {
                        eventLog.removeLast()
                    }
                }
            }
            
            // Listen to system events
            store.getEventBus().subscribe(to: SystemEvent.self) { event in
                print("System Event: \(event.event)")
                
                // Handle events from second page
                if event.event == "navigation" && event.details["action"] == "back_to_first" {
                    eventLog.insert("🏠 Second page returned to first page", at: 0)
                    if eventLog.count > 20 {
                        eventLog.removeLast()
                    }
                }
            }
        }
    }
    
    private func publishEvent(_ name: String) {
        Task { @MainActor in
            store.getEventBus().publishSystemEvent(event: name, details: ["timestamp": Date().description])
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: AppState.Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
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
                    .background(bubbleColor)
                    .foregroundColor(bubbleTextColor)
                    .cornerRadius(16)
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private var bubbleColor: Color {
        isFromCurrentUser ? .blue : Color(.systemGray5)
    }
    
    private var bubbleTextColor: Color {
        isFromCurrentUser ? .white : .primary
    }
}

// MARK: - Typing Indicator View
struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
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
        .onAppear {
            animationOffset = 1.0
        }
    }
}

// MARK: - Event Bus Demo View
struct EventBusDemoView: View {
    @ObservedObject var store: AppStore
    @Binding var eventLog: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Bus Demo")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button("Event 1") {
                    Task { @MainActor in
                        store.getEventBus().publishSystemEvent(
                            event: "button_click",
                            details: ["button": "event_1", "timestamp": Date().description]
                        )
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Event 2") {
                    Task { @MainActor in
                        store.getEventBus().publishSystemEvent(
                            event: "button_click",
                            details: ["button": "event_2", "timestamp": Date().description]
                        )
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Event 3") {
                    Task { @MainActor in
                        store.getEventBus().publishSystemEvent(
                            event: "button_click",
                            details: ["button": "event_3", "timestamp": Date().description]
                        )
                    }
                }
                .buttonStyle(.bordered)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Log")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
                .frame(maxHeight: 150)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
