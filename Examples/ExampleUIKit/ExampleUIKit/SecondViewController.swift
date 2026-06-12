import UIKit
import Rex

class SecondViewController: UIViewController {
    private let environment: AppEnvironment
    private var graphStore: GraphStore<AppReducer> { environment.graphStore }
    private var store: Store<AppReducer> { environment.store }

    private let logTextView = UITextView()

    init(environment: AppEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStoreSubscription()
        store.dispatch(.logActivity("🚀 SecondViewController appeared"))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            store.dispatch(.delegate(.navigatedBack))
            graphStore.pop()
            store.dispatch(.logActivity("👋 SecondViewController unmounted"))
        }
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Second Page"

        logTextView.font = .systemFont(ofSize: 12)
        logTextView.backgroundColor = .systemGray6
        logTextView.layer.cornerRadius = 8
        logTextView.isEditable = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logTextView)

        let sendMessageButton = createButton(title: "Send Message to First Page", color: .systemBlue)
        let addScoreButton = createButton(title: "Add Score from Second Page", color: .systemGreen)
        let goBackButton = createButton(title: "Go Back", color: .systemRed)

        NSLayoutConstraint.activate([
            sendMessageButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            sendMessageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendMessageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendMessageButton.heightAnchor.constraint(equalToConstant: 44),

            addScoreButton.topAnchor.constraint(equalTo: sendMessageButton.bottomAnchor, constant: 12),
            addScoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addScoreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addScoreButton.heightAnchor.constraint(equalToConstant: 44),

            goBackButton.topAnchor.constraint(equalTo: addScoreButton.bottomAnchor, constant: 12),
            goBackButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            goBackButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            goBackButton.heightAnchor.constraint(equalToConstant: 44),

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
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return button
    }

    private func setupStoreSubscription() {
        store.subscribe { [weak self] state in
            DispatchQueue.main.async {
                self?.logTextView.text = state.activityLog.map(\.formatted).joined(separator: "\n")
            }
        }
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }

        switch sender.title(for: .normal) {
        case "Send Message to First Page":
            store.dispatch(.delegate(.messageToFirst("Hello from Second Page!")))
        case "Add Score from Second Page":
            store.dispatch(.delegate(.addScoreFromSecond(25)))
        case "Go Back":
            navigationController?.popViewController(animated: true)
        default:
            break
        }
    }
}
