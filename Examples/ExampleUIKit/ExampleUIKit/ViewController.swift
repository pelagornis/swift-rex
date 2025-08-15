import UIKit
import Rex
import Combine

class ViewController: UIViewController {
    private let store: Store<AppReducer>
    private var cancellables: Set<AnyCancellable> = []
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let levelLabel = UILabel()
    private let livesLabel = UILabel()
    private let gameStatusLabel = UILabel()
    private let logTextView = UITextView()
    
    // Buttons
    private let startGameButton = UIButton()
    private let endGameButton = UIButton()
    private let addScoreButton = UIButton()
    private let loseLifeButton = UIButton()
    private let event1Button = UIButton()
    private let event2Button = UIButton()
    private let event3Button = UIButton()
    private let secondPageButton = UIButton()
    
    init() {
        self.store = Store(
            initialState: AppState(),
            reducer: AppReducer()
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStoreSubscription()
        setupEventBus()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // ScrollView setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "Game App"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Game Stats
        scoreLabel.text = "Score: 0"
        scoreLabel.font = .systemFont(ofSize: 18)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreLabel)
        
        levelLabel.text = "Level: 1"
        levelLabel.font = .systemFont(ofSize: 18)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelLabel)
        
        livesLabel.text = "Lives: 3"
        livesLabel.font = .systemFont(ofSize: 18)
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(livesLabel)
        
        gameStatusLabel.text = "Game Status: Not Started"
        gameStatusLabel.font = .systemFont(ofSize: 16)
        gameStatusLabel.textColor = .secondaryLabel
        gameStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gameStatusLabel)
        
        // Buttons
        setupButton(startGameButton, title: "Start Game", color: .systemGreen)
        setupButton(endGameButton, title: "End Game", color: .systemRed)
        setupButton(addScoreButton, title: "Add Score", color: .systemBlue)
        setupButton(loseLifeButton, title: "Lose Life", color: .systemOrange)
        setupButton(event1Button, title: "Event 1", color: .systemPurple)
        setupButton(event2Button, title: "Event 2", color: .systemIndigo)
        setupButton(event3Button, title: "Event 3", color: .systemTeal)
        setupButton(secondPageButton, title: "Go to Second Page", color: .systemPink)
        
        // Log TextView
        logTextView.text = "Events will appear here...\n"
        logTextView.font = .systemFont(ofSize: 12)
        logTextView.backgroundColor = .systemGray6
        logTextView.layer.cornerRadius = 8
        logTextView.isEditable = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(logTextView)
        
        setupConstraints()
    }
    
    private func setupButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)
        
        // Add touch feedback
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Game Stats
            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            levelLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            levelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            livesLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 8),
            livesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            gameStatusLabel.topAnchor.constraint(equalTo: livesLabel.bottomAnchor, constant: 8),
            gameStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            // Buttons - First Row
            startGameButton.topAnchor.constraint(equalTo: gameStatusLabel.bottomAnchor, constant: 20),
            startGameButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startGameButton.widthAnchor.constraint(equalToConstant: 120),
            startGameButton.heightAnchor.constraint(equalToConstant: 44),
            
            endGameButton.topAnchor.constraint(equalTo: startGameButton.topAnchor),
            endGameButton.leadingAnchor.constraint(equalTo: startGameButton.trailingAnchor, constant: 10),
            endGameButton.widthAnchor.constraint(equalToConstant: 120),
            endGameButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Buttons - Second Row
            addScoreButton.topAnchor.constraint(equalTo: startGameButton.bottomAnchor, constant: 10),
            addScoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addScoreButton.widthAnchor.constraint(equalToConstant: 120),
            addScoreButton.heightAnchor.constraint(equalToConstant: 44),
            
            loseLifeButton.topAnchor.constraint(equalTo: addScoreButton.topAnchor),
            loseLifeButton.leadingAnchor.constraint(equalTo: addScoreButton.trailingAnchor, constant: 10),
            loseLifeButton.widthAnchor.constraint(equalToConstant: 120),
            loseLifeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Buttons - Third Row
            event1Button.topAnchor.constraint(equalTo: addScoreButton.bottomAnchor, constant: 10),
            event1Button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            event1Button.widthAnchor.constraint(equalToConstant: 80),
            event1Button.heightAnchor.constraint(equalToConstant: 44),
            
            event2Button.topAnchor.constraint(equalTo: event1Button.topAnchor),
            event2Button.leadingAnchor.constraint(equalTo: event1Button.trailingAnchor, constant: 10),
            event2Button.widthAnchor.constraint(equalToConstant: 80),
            event2Button.heightAnchor.constraint(equalToConstant: 44),
            
            event3Button.topAnchor.constraint(equalTo: event2Button.topAnchor),
            event3Button.leadingAnchor.constraint(equalTo: event2Button.trailingAnchor, constant: 10),
            event3Button.widthAnchor.constraint(equalToConstant: 80),
            event3Button.heightAnchor.constraint(equalToConstant: 44),
            
            // Second Page Button
            secondPageButton.topAnchor.constraint(equalTo: event1Button.bottomAnchor, constant: 20),
            secondPageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            secondPageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            secondPageButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Log TextView
            logTextView.topAnchor.constraint(equalTo: secondPageButton.bottomAnchor, constant: 20),
            logTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logTextView.heightAnchor.constraint(equalToConstant: 200),
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
    
    // MARK: - Event Bus Setup
    private func setupEventBus() {
        Task { @MainActor in
            // Subscribe to all events
            store.getEventBus().subscribe { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 Event: \(type(of: event))")
                }
            }
            
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
            
            store.getEventBus().subscribe(to: NavigationEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("🧭 Navigation: \(event.route)")
                    
                    // Handle navigation events from second page
                    if event.route == "back_to_first" {
                        self?.addLog("🏠 Second page returned to first page")
                    }
                }
            }
            
            store.getEventBus().subscribe(to: UserActionEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("👤 User Action: \(event.action)")
                }
            }
            
            addLog("🚀 EventBus subscriptions setup complete")
        }
    }
    
    // MARK: - UI Updates
    private func updateUI(with state: AppState) {
        scoreLabel.text = "Score: \(state.score)"
        levelLabel.text = "Level: \(state.level)"
        livesLabel.text = "Lives: \(state.lives)"
        gameStatusLabel.text = "Game Status: \(state.isGameActive ? "Active" : "Not Started")"
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
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "event_1", data: ["message": "Event 1 triggered!"]))
            addLog("📤 Event 1 published")
        }
    }
    
    @objc private func event2() {
        print("Event 2 tapped")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "event_2", data: ["message": "Event 2 triggered!"]))
            addLog("📤 Event 2 published")
        }
    }
    
    @objc private func event3() {
        print("Event 3 tapped")
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(name: "event_3", data: ["message": "Event 3 triggered!"]))
            addLog("📤 Event 3 published")
        }
    }
    
    @objc private func goToSecondPage() {
        print("Go to Second Page tapped")
        let secondVC = SecondViewController(store: store)
        navigationController?.pushViewController(secondVC, animated: true)
    }
    
    // MARK: - Button Touch Feedback
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
        }
        
        // Handle button actions
        switch sender {
        case startGameButton:
            startGame()
        case endGameButton:
            endGame()
        case addScoreButton:
            addScore()
        case loseLifeButton:
            loseLife()
        case event1Button:
            event1()
        case event2Button:
            event2()
        case event3Button:
            event3()
        case secondPageButton:
            goToSecondPage()
        default:
            break
        }
    }
}
