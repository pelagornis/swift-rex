import UIKit
import Rex
import Combine

class ViewController: UIViewController {
    
    // MARK: - Properties
    let store: Store<AppReducer>
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let levelLabel = UILabel()
    private let livesLabel = UILabel()
    
    private let startButton = UIButton(type: .system)
    private let endButton = UIButton(type: .system)
    private let scoreButton = UIButton(type: .system)
    private let lifeButton = UIButton(type: .system)
    
    private let eventButton1 = UIButton(type: .system)
    private let eventButton2 = UIButton(type: .system)
    private let eventButton3 = UIButton(type: .system)
    private let secondPageButton = UIButton(type: .system)
    
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
        setupStoreSubscription()
        setupEventBus()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Labels
        titleLabel.text = "Game Center"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        scoreLabel.text = "Score: 0"
        scoreLabel.font = .systemFont(ofSize: 18)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        levelLabel.text = "Level: 1"
        levelLabel.font = .systemFont(ofSize: 18)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        
        livesLabel.text = "Lives: 3"
        livesLabel.font = .systemFont(ofSize: 18)
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        setupButton(startButton, title: "Start Game", color: .systemGreen)
        setupButton(endButton, title: "End Game", color: .systemRed)
        setupButton(scoreButton, title: "Add Score", color: .systemBlue)
        setupButton(lifeButton, title: "Lose Life", color: .systemOrange)
        
        setupButton(eventButton1, title: "Event 1", color: .systemPurple)
        setupButton(eventButton2, title: "Event 2", color: .systemTeal)
        setupButton(eventButton3, title: "Event 3", color: .systemIndigo)
        setupButton(secondPageButton, title: "Go to Second Page", color: .systemBrown)
        
        // Log Text View
        logTextView.text = "Events will appear here..."
        logTextView.font = .systemFont(ofSize: 14)
        logTextView.backgroundColor = .systemGray6
        logTextView.layer.cornerRadius = 8
        logTextView.isEditable = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add targets
        startButton.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(endGame), for: .touchUpInside)
        scoreButton.addTarget(self, action: #selector(addScore), for: .touchUpInside)
        lifeButton.addTarget(self, action: #selector(loseLife), for: .touchUpInside)
        
        eventButton1.addTarget(self, action: #selector(event1), for: .touchUpInside)
        eventButton2.addTarget(self, action: #selector(event2), for: .touchUpInside)
        eventButton3.addTarget(self, action: #selector(event3), for: .touchUpInside)
        secondPageButton.addTarget(self, action: #selector(goToSecondPage), for: .touchUpInside)
        
        // View hierarchy
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(levelLabel)
        contentView.addSubview(livesLabel)
        contentView.addSubview(startButton)
        contentView.addSubview(endButton)
        contentView.addSubview(scoreButton)
        contentView.addSubview(lifeButton)
        contentView.addSubview(eventButton1)
        contentView.addSubview(eventButton2)
        contentView.addSubview(eventButton3)
        contentView.addSubview(secondPageButton)
        contentView.addSubview(logTextView)
    }
    
    private func setupButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // Add touch feedback
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Stats
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            scoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            levelLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            levelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            levelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            livesLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 10),
            livesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            livesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Game Buttons
            startButton.topAnchor.constraint(equalTo: livesLabel.bottomAnchor, constant: 30),
            startButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            endButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 12),
            endButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            endButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            scoreButton.topAnchor.constraint(equalTo: endButton.bottomAnchor, constant: 12),
            scoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            lifeButton.topAnchor.constraint(equalTo: scoreButton.bottomAnchor, constant: 12),
            lifeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lifeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Event Buttons
            eventButton1.topAnchor.constraint(equalTo: lifeButton.bottomAnchor, constant: 30),
            eventButton1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventButton1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            eventButton2.topAnchor.constraint(equalTo: eventButton1.bottomAnchor, constant: 12),
            eventButton2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventButton2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            eventButton3.topAnchor.constraint(equalTo: eventButton2.bottomAnchor, constant: 12),
            eventButton3.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            eventButton3.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            secondPageButton.topAnchor.constraint(equalTo: eventButton3.bottomAnchor, constant: 12),
            secondPageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            secondPageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Log
            logTextView.topAnchor.constraint(equalTo: secondPageButton.bottomAnchor, constant: 30),
            logTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logTextView.heightAnchor.constraint(equalToConstant: 150),
            logTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Store Subscription
    private func setupStoreSubscription() {
        store.subscribe { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(with: state)
            }
        }
    }
    
    // MARK: - Event Bus
    private func setupEventBus() {
        print("Setting up EventBus subscriptions...")
        
        Task { @MainActor in
            // Subscribe to all events
            store.getEventBus().subscribe { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 Event: \(type(of: event))")
                }
            }
            .store(in: &cancellables)
            
            // Subscribe to specific event types
            store.getEventBus().subscribe(to: AppEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 App Event: \(event.name)")
                    
                    // Handle events from second page
                    if event.name == "message_from_second_page" {
                        self?.addLog("💬 Message from Second Page: \(event.data["message"] ?? "No message")")
                    }
                }
            }
            .store(in: &cancellables)
            
            store.getEventBus().subscribe(to: NavigationEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("🧭 Navigation: \(event.route)")
                    
                    // Handle navigation events from second page
                    if event.route == "back_to_first" {
                        self?.addLog("🏠 Second page returned to first page")
                    }
                }
            }
            .store(in: &cancellables)
            
            store.getEventBus().subscribe(to: UserActionEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("👤 User Action: \(event.action)")
                }
            }
            .store(in: &cancellables)
            
            addLog("🚀 EventBus subscriptions setup complete")
        }
    }
    
    // MARK: - UI Updates
    private func updateUI(with state: AppState) {
        scoreLabel.text = "Score: \(state.score)"
        levelLabel.text = "Level: \(state.level)"
        livesLabel.text = "Lives: \(state.lives)"
    }
    
    private func addLog(_ message: String) {
        print("Adding log: \(message)")
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logEntry = "[\(timestamp)] \(message)\n"
        logTextView.text += logEntry
        
        let bottom = NSMakeRange(logTextView.text.count - 1, 1)
        logTextView.scrollRangeToVisible(bottom)
    }
    
    // MARK: - Actions
    @objc private func startGame() {
        print("Start Game tapped")
        store.dispatch(AppAction.startGame)
        print("Publishing game_started event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "game_started", data: ["message": "Game started!"]))
        }
    }
    
    @objc private func endGame() {
        print("End Game tapped")
        store.dispatch(AppAction.endGame)
        print("Publishing game_ended event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "game_ended", data: ["message": "Game ended!"]))
        }
    }
    
    @objc private func addScore() {
        print("Add Score tapped")
        store.dispatch(AppAction.addScore(Int.random(in: 10...50)))
        print("Publishing score_added event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "score_added", data: ["message": "Score added!"]))
        }
    }
    
    @objc private func loseLife() {
        print("Lose Life tapped")
        store.dispatch(AppAction.loseLife)
        print("Publishing life_lost event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "life_lost", data: ["message": "Life lost!"]))
        }
    }
    
    @objc private func event1() {
        print("Event 1 tapped")
        addLog("🎯 Event 1 Button Pressed")
        store.dispatch(AppAction.triggerScoreEvent)
        print("Publishing score_event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "score_event", data: ["message": "Score event triggered!"]))
        }
    }
    
    @objc private func event2() {
        print("Event 2 tapped")
        addLog("🎯 Event 2 Button Pressed")
        store.dispatch(AppAction.triggerLevelUpEvent)
        print("Publishing level_up_event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "level_up_event", data: ["message": "Level up event triggered!"]))
        }
    }
    
    @objc private func event3() {
        print("Event 3 tapped")
        addLog("🎯 Event 3 Button Pressed")
        store.dispatch(AppAction.triggerPowerUpEvent)
        print("Publishing power_up_event...")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "power_up_event", data: ["message": "Power up event triggered!"]))
        }
    }
    
    @objc private func goToSecondPage() {
        print("Go to Second Page tapped")
        addLog("📱 Navigating to Second Page")
        
        // Send navigation event before presenting
        Task { @MainActor in
            store.getEventBus().publish(NavigationEvent(route: "first_to_second", parameters: ["action": "navigate"]))
        }
        
        let secondVC = SecondViewController(store: store)
        secondVC.modalPresentationStyle = .fullScreen
        present(secondVC, animated: true)
    }
}
