import UIKit
import Rex

class SecondViewController: UIViewController {
    private let store: Store<AppReducer>
    private let logTextView = UITextView()
    
    init(store: Store<AppReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEventBus()
        addLog("🚀 SecondViewController appeared")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Second Page"
        
        // Log TextView
        logTextView.text = "Events will appear here...\n"
        logTextView.font = .systemFont(ofSize: 12)
        logTextView.backgroundColor = .systemGray6
        logTextView.layer.cornerRadius = 8
        logTextView.isEditable = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logTextView)
        
        // Buttons
        let sendMessageButton = createButton(title: "Send Message to First Page", color: .systemBlue)
        let addScoreButton = createButton(title: "Add Score from Second Page", color: .systemGreen)
        let goBackButton = createButton(title: "Go Back", color: .systemRed)
        
        NSLayoutConstraint.activate([
            // Send Message Button
            sendMessageButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            sendMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Add Score Button
            addScoreButton.topAnchor.constraint(equalTo: sendMessageButton.bottomAnchor, constant: 12),
            addScoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addScoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addScoreButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Go Back Button
            goBackButton.topAnchor.constraint(equalTo: addScoreButton.bottomAnchor, constant: 12),
            goBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            goBackButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            goBackButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Log TextView
            logTextView.topAnchor.constraint(equalTo: goBackButton.bottomAnchor, constant: 20),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        // Add touch feedback
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    // MARK: - Event Bus Setup
    private func setupEventBus() {
        Task { @MainActor in
            // Subscribe to all events
            store.getEventBus().subscribe { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 All Event: \(type(of: event))")
                }
            }
            
            // Subscribe to app events
            store.getEventBus().subscribe(to: AppEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("📱 App Event: \(event.name)")
                }
            }
            
            // Subscribe to navigation events
            store.getEventBus().subscribe(to: NavigationEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("🧭 Navigation: \(event.route)")
                }
            }
            
            // Subscribe to user action events
            store.getEventBus().subscribe(to: UserActionEvent.self) { [weak self] event in
                DispatchQueue.main.async {
                    self?.addLog("👤 User Action: \(event.action)")
                }
            }
            
            addLog("🚀 EventBus subscriptions setup complete")
        }
    }
    
    // MARK: - Actions
    private func sendMessage() {
        addLog("📤 Sending message to first page")
        
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(
                name: "message_from_second_page",
                data: ["message": "Hello from Second Page!", "timestamp": Date().description]
            ))
            addLog("📤 Message published to first page")
        }
    }
    
    private func addScore() {
        addLog("📤 Adding score from second page")
        
        Task { @MainActor in
            store.getEventBus().publish(AppEvent(
                name: "score_from_second_page",
                data: ["score": "25", "timestamp": Date().description]
            ))
            addLog("📤 Score event published")
        }
    }
    
    private func goBack() {
        addLog("🔙 Going back to first page")
        
        Task { @MainActor in
            store.getEventBus().publish(NavigationEvent(
                route: "back_to_first",
                parameters: ["from": "second_page", "timestamp": Date().description]
            ))
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    private func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logEntry = "[\(timestamp)] \(message)\n"
        logTextView.text += logEntry
        
        let bottom = NSMakeRange(logTextView.text.count - 1, 1)
        logTextView.scrollRangeToVisible(bottom)
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
        switch sender.title(for: .normal) {
        case "Send Message to First Page":
            sendMessage()
        case "Add Score from Second Page":
            addScore()
        case "Go Back":
            goBack()
        default:
            break
        }
    }
}
