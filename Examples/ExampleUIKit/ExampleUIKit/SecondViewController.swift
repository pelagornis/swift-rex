import UIKit
import Rex
import Combine

class SecondViewController: UIViewController {
    
    // MARK: - Properties
    let store: Store<AppReducer>
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let scoreLabel = UILabel()
    private let levelLabel = UILabel()
    private let livesLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let addScoreButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    private let logTextView = UITextView()
    
    // MARK: - Initialization
    init(store: Store<AppReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupEventBus()
        setupStoreSubscription()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.text = "Second Page"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLabel.text = "Waiting for events from first page..."
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.text = "Score: 0"
        scoreLabel.font = .systemFont(ofSize: 18)
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        levelLabel.text = "Level: 1"
        levelLabel.font = .systemFont(ofSize: 18)
        levelLabel.textAlignment = .center
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        livesLabel.text = "Lives: 3"
        livesLabel.font = .systemFont(ofSize: 18)
        livesLabel.textAlignment = .center
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        setupButton(sendButton, title: "Send Message to First Page", color: .systemBlue)
        setupButton(addScoreButton, title: "Add Score from Second Page", color: .systemGreen)
        setupButton(backButton, title: "Back to First Page", color: .systemGray)
        
        logTextView.text = "Events from first page will appear here..."
        logTextView.font = .systemFont(ofSize: 14)
        logTextView.backgroundColor = .systemGray6
        logTextView.layer.cornerRadius = 8
        logTextView.isEditable = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add targets
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        addScoreButton.addTarget(self, action: #selector(addScore), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        
        // View hierarchy
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(scoreLabel)
        view.addSubview(levelLabel)
        view.addSubview(livesLabel)
        view.addSubview(sendButton)
        view.addSubview(addScoreButton)
        view.addSubview(backButton)
        view.addSubview(logTextView)
    }
    
    private func setupButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scoreLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            levelLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            levelLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            levelLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            livesLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 10),
            livesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            livesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            sendButton.topAnchor.constraint(equalTo: livesLabel.bottomAnchor, constant: 30),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            addScoreButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 12),
            addScoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addScoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            backButton.topAnchor.constraint(equalTo: addScoreButton.bottomAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            logTextView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 30),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Event Bus
    private func setupEventBus() {
        print("SecondViewController: Setting up EventBus subscriptions...")
        
        Task { @MainActor in
            // Subscribe to all events first
            store.getEventBus().subscribe { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 All Event: \(type(of: event))")
                }
            }
            .store(in: &cancellables)
            
            // Listen to events from first page
            store.getEventBus().subscribe(to: AppEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 Received from First Page: \(event.name)")
                    self?.messageLabel.text = "Received: \(event.name)"
                }
            }
            .store(in: &cancellables)
            
            // Listen to navigation events
            store.getEventBus().subscribe(to: NavigationEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("🧭 Navigation: \(event.route)")
                }
            }
            .store(in: &cancellables)
            
            // Listen to user action events
            store.getEventBus().subscribe(to: UserActionEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("👤 User Action: \(event.action)")
                }
            }
            .store(in: &cancellables)
            
            // Add initial log
            addLog("🚀 SecondViewController EventBus setup complete")
        }
    }
    
    // MARK: - Store Subscription
    private func setupStoreSubscription() {
        print("SecondViewController: Setting up Store subscription...")
        store.subscribe { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(with: state)
            }
        }
        addLog("📊 Store subscription setup complete")
    }
    
    // MARK: - UI Updates
    private func updateUI(with state: AppState) {
        // Update UI based on store state
        scoreLabel.text = "Score: \(state.score)"
        levelLabel.text = "Level: \(state.level)"
        livesLabel.text = "Lives: \(state.lives)"
        
        addLog("📊 Store state updated: Score=\(state.score), Level=\(state.level), Lives=\(state.lives)")
    }
    
    private func addLog(_ message: String) {
        print("SecondViewController: \(message)")
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logEntry = "[\(timestamp)] \(message)\n"
        logTextView.text += logEntry
        
        let bottom = NSMakeRange(logTextView.text.count - 1, 1)
        logTextView.scrollRangeToVisible(bottom)
    }
    
    // MARK: - Actions
    @objc private func sendMessage() {
        print("SecondViewController: Sending message to first page")
        addLog("📤 Sending message to first page")
        
        // Send event to first page
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "message_from_second_page", data: ["message": "Hello from Second Page!"]))
            addLog("📤 AppEvent published: message_from_second_page")
            
            // Also send navigation event
            store.getEventBus().publish(NavigationEvent(route: "second_to_first", parameters: ["action": "message_sent"]))
            addLog("📤 NavigationEvent published: second_to_first")
        }
    }
    
    @objc private func addScore() {
        print("SecondViewController: Adding score from second page")
        addLog("🎯 Adding score from second page")
        
        // Dispatch store action to add score
        store.dispatch(AppAction.addScore(Int.random(in: 20...100)))
        
        // Send event to first page
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "score_added_from_second", data: ["message": "Score added from second page!"]))
            addLog("📤 Score event published from second page")
        }
    }
    
    @objc private func goBack() {
        print("SecondViewController: Going back to first page")
        addLog("🔙 Going back to first page")
        
        // Send navigation event before going back
        Task { @MainActor in
            store.getEventBus().publish(NavigationEvent(route: "back_to_first", parameters: ["from": "second_page"]))
        }
        
        dismiss(animated: true)
    }
}
