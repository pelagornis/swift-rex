import UIKit
import Rex

class ViewController: UIViewController {
    private let store: Store<AppReducer>
    private var state: AppState

    private let label = UILabel()
    private let incrementButton = UIButton(type: .system)
    private let decrementButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let loadButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init(store: Store<AppReducer>) {
        self.store = store
        self.state = store.state
        super.init(nibName: nil, bundle: nil)

        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.state = newState
                self?.updateUI()
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        label.translatesAutoresizingMaskIntoConstraints = false
        incrementButton.translatesAutoresizingMaskIntoConstraints = false
        decrementButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        loadButton.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24)

        incrementButton.setTitle("Increment", for: .normal)
        decrementButton.setTitle("Decrement", for: .normal)
        resetButton.setTitle("Reset with Just", for: .normal)
        loadButton.setTitle("Load", for: .normal)

        incrementButton.addTarget(self, action: #selector(increment), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(decrement), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        loadButton.addTarget(self, action: #selector(load), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(incrementButton)
        view.addSubview(decrementButton)
        view.addSubview(resetButton)
        view.addSubview(loadButton)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            incrementButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            incrementButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),

            decrementButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            decrementButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),

            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.topAnchor.constraint(equalTo: incrementButton.bottomAnchor, constant: 20),

            loadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadButton.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 20),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: loadButton.bottomAnchor, constant: 20)
        ])

        updateUI()
    }

    private func updateUI() {
        label.text = "Count: \(state.count)"
        state.isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    @objc private func increment() { store.dispatch(.increment) }
    @objc private func decrement() { store.dispatch(.decrement) }
    @objc private func reset() { store.dispatch(.reset) }
    @objc private func load() { store.dispatch(.loadFromServer) }
}
