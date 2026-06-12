import UIKit
import Rex

class ViewController: UIViewController {
    private let environment = AppEnvironment()
    private var graphStore: GraphStore<AppReducer> { environment.graphStore }
    private var store: Store<AppReducer> { environment.store }

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let scoreLabel = UILabel()
    private let levelLabel = UILabel()
    private let livesLabel = UILabel()
    private let gameStatusLabel = UILabel()
    private let graphLabel = UILabel()
    private let logTextView = UITextView()

    private let startGameButton = UIButton()
    private let endGameButton = UIButton()
    private let addScoreButton = UIButton()
    private let loseLifeButton = UIButton()
    private let event1Button = UIButton()
    private let event2Button = UIButton()
    private let event3Button = UIButton()
    private let secondPageButton = UIButton()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupStoreSubscription()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        titleLabel.text = "Game App"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        scoreLabel.font = .systemFont(ofSize: 18)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scoreLabel)

        levelLabel.font = .systemFont(ofSize: 18)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelLabel)

        livesLabel.font = .systemFont(ofSize: 18)
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(livesLabel)

        gameStatusLabel.font = .systemFont(ofSize: 16)
        gameStatusLabel.textColor = .secondaryLabel
        gameStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gameStatusLabel)

        graphLabel.font = .systemFont(ofSize: 14)
        graphLabel.textColor = .secondaryLabel
        graphLabel.numberOfLines = 0
        graphLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(graphLabel)

        setupButton(startGameButton, title: "Start Game", color: .systemGreen)
        setupButton(endGameButton, title: "End Game", color: .systemRed)
        setupButton(addScoreButton, title: "Add Score", color: .systemBlue)
        setupButton(loseLifeButton, title: "Lose Life", color: .systemOrange)
        setupButton(event1Button, title: "Power Up", color: .systemPurple)
        setupButton(event2Button, title: "Level Up", color: .systemIndigo)
        setupButton(event3Button, title: "Achievement", color: .systemTeal)
        setupButton(secondPageButton, title: "Go to Second Page", color: .systemPink)

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
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            scoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            levelLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 8),
            levelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            livesLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 8),
            livesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            gameStatusLabel.topAnchor.constraint(equalTo: livesLabel.bottomAnchor, constant: 8),
            gameStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            graphLabel.topAnchor.constraint(equalTo: gameStatusLabel.bottomAnchor, constant: 8),
            graphLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            graphLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            startGameButton.topAnchor.constraint(equalTo: graphLabel.bottomAnchor, constant: 20),
            startGameButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            startGameButton.widthAnchor.constraint(equalToConstant: 120),
            startGameButton.heightAnchor.constraint(equalToConstant: 44),

            endGameButton.topAnchor.constraint(equalTo: startGameButton.topAnchor),
            endGameButton.leadingAnchor.constraint(equalTo: startGameButton.trailingAnchor, constant: 10),
            endGameButton.widthAnchor.constraint(equalToConstant: 120),
            endGameButton.heightAnchor.constraint(equalToConstant: 44),

            addScoreButton.topAnchor.constraint(equalTo: startGameButton.bottomAnchor, constant: 10),
            addScoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addScoreButton.widthAnchor.constraint(equalToConstant: 120),
            addScoreButton.heightAnchor.constraint(equalToConstant: 44),

            loseLifeButton.topAnchor.constraint(equalTo: addScoreButton.topAnchor),
            loseLifeButton.leadingAnchor.constraint(equalTo: addScoreButton.trailingAnchor, constant: 10),
            loseLifeButton.widthAnchor.constraint(equalToConstant: 120),
            loseLifeButton.heightAnchor.constraint(equalToConstant: 44),

            event1Button.topAnchor.constraint(equalTo: addScoreButton.bottomAnchor, constant: 10),
            event1Button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            event1Button.widthAnchor.constraint(equalToConstant: 100),
            event1Button.heightAnchor.constraint(equalToConstant: 44),

            event2Button.topAnchor.constraint(equalTo: event1Button.topAnchor),
            event2Button.leadingAnchor.constraint(equalTo: event1Button.trailingAnchor, constant: 10),
            event2Button.widthAnchor.constraint(equalToConstant: 100),
            event2Button.heightAnchor.constraint(equalToConstant: 44),

            event3Button.topAnchor.constraint(equalTo: event2Button.topAnchor),
            event3Button.leadingAnchor.constraint(equalTo: event2Button.trailingAnchor, constant: 10),
            event3Button.widthAnchor.constraint(equalToConstant: 100),
            event3Button.heightAnchor.constraint(equalToConstant: 44),

            secondPageButton.topAnchor.constraint(equalTo: event1Button.bottomAnchor, constant: 20),
            secondPageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            secondPageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            secondPageButton.heightAnchor.constraint(equalToConstant: 44),

            logTextView.topAnchor.constraint(equalTo: secondPageButton.bottomAnchor, constant: 20),
            logTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logTextView.heightAnchor.constraint(equalToConstant: 220),
            logTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func setupStoreSubscription() {
        store.subscribe { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(with: state)
            }
        }
    }

    private func updateUI(with state: AppState) {
        scoreLabel.text = "Score: \(state.score)"
        levelLabel.text = "Level: \(state.level)"
        livesLabel.text = "Lives: \(state.lives)"
        gameStatusLabel.text = "Game Status: \(state.isGameActive ? "Active" : "Not Started")"
        graphLabel.text = "Graph: \(state.graph.activePath.map(\.rawValue).joined(separator: " → "))"

        logTextView.text = state.activityLog.map(\.formatted).joined(separator: "\n")
        let bottom = NSRange(location: max(logTextView.text.count - 1, 0), length: 1)
        logTextView.scrollRangeToVisible(bottom)
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

        switch sender {
        case startGameButton:
            store.dispatch(.startGame)
        case endGameButton:
            store.dispatch(.endGame)
        case addScoreButton:
            store.dispatch(.addScore(Int.random(in: 10...50)))
        case loseLifeButton:
            store.dispatch(.loseLife)
        case event1Button:
            store.dispatch(.triggerPowerUpEvent)
        case event2Button:
            store.dispatch(.triggerLevelUpEvent)
        case event3Button:
            store.dispatch(.triggerAchievementEvent)
        case secondPageButton:
            graphStore.push("second")
            let secondVC = SecondViewController(environment: environment)
            navigationController?.pushViewController(secondVC, animated: true)
        default:
            break
        }
    }
}
