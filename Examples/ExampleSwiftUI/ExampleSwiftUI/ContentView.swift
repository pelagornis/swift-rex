import SwiftUI
import Rex
import Combine

struct ContentView: View {
    @StateObject var store: AppStore
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var eventLog: [String] = []
    @State private var messageText: String = ""
    @State private var showingEventBus = false
    @State private var showingSecondPage = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Swift-Rex Chat")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Online: \(store.state.onlineUsers.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if store.state.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading...")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(store.state.messages) { message in
                                MessageBubbleView(message: message, isFromCurrentUser: message.sender.id == store.state.currentUser.id)
                                    .id(message.id)
                            }
                            
                            if store.state.isTyping {
                                TypingIndicatorView()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.state.messages.count) { _ in
                        if let lastMessage = store.state.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                VStack(spacing: 8) {
                    HStack {
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button("Send") {
                            sendMessage()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(messageText.isEmpty)
                    }
                    
                    // Event Bus Demo Buttons
                    HStack(spacing: 8) {
                        Button("Event Bus Demo") {
                            showingEventBus.toggle()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Second Page") {
                            showingSecondPage.toggle()
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                        
                        Spacer()
                        
                        Button("Load Messages") {
                            store.send(.loadMessages)
                            publishEvent("Messages Loaded")
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.state.isLoading)
                        
                        Button("Clear") {
                            store.send(.clearMessages)
                            publishEvent("Messages Cleared")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingEventBus) {
            EventBusDemoView(store: store, eventLog: $eventLog)
        }
        .sheet(isPresented: $showingSecondPage) {
            SecondView(store: store)
        }
        .onAppear {
            setupEventListeners()
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        store.send(.sendMessage(messageText))
        publishEvent("Message Sent")
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
            .store(in: &cancellables)
            
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
            .store(in: &cancellables)
            
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
            .store(in: &cancellables)
            
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
            .store(in: &cancellables)
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
        switch message.type {
        case .system:
            return Color(.systemGray5)
        case .text, .image:
            return isFromCurrentUser ? .blue : Color(.systemGray6)
        }
    }
    
    private var bubbleTextColor: Color {
        switch message.type {
        case .system:
            return .secondary
        case .text, .image:
            return isFromCurrentUser ? .white : .primary
        }
    }
}

// MARK: - Typing Indicator View
struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            Text("🤖")
                .font(.title2)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + animationOffset)
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
            
            Spacer()
        }
        .onAppear {
            animationOffset = 0.3
        }
    }
}

// MARK: - Event Bus Demo View
struct EventBusDemoView: View {
    @ObservedObject var store: AppStore
    @Binding var eventLog: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Event Bus Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    Button("User Join") {
                        store.send(.triggerUserJoin)
                        publishEvent("User Join Event")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("User Leave") {
                        store.send(.triggerUserLeave)
                        publishEvent("User Leave Event")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Send Bot Message") {
                        store.send(.triggerMessageSent)
                        publishEvent("Bot Message Event")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Typing Indicator") {
                        store.send(.triggerTyping)
                        publishEvent("Typing Event")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("System Event") {
                        store.send(.triggerSystemEvent)
                        publishEvent("System Event")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Log")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(eventLog.prefix(10), id: \.self) { event in
                                Text("• \(event)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Event Bus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func publishEvent(_ name: String) {
        Task { @MainActor in
            store.getEventBus().publishAppEvent(name: name, data: ["timestamp": Date().description])
        }
    }
}

#Preview {
    ContentView(store: AppStore(store: Store(
        initialState: AppState(),
        reducer: AppReducer()
    )))
}
