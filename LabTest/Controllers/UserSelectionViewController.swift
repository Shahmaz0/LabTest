//
//  UserSelectionViewController.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit
import Combine

// MARK: - Signup Delegate
protocol SignupDelegate: AnyObject {
    func signupCompleted()
}

final class UserSelectionViewController: BaseViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let addUserButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    // MARK: - Properties
    private var userManager: any UserManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(userManager: any UserManagerProtocol) {
        self.userManager = userManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        // We'll set userManager in viewDidLoad when we have access to coordinator
        self.userManager = UserManager()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up userManager with shared instance if available
        if let sharedUserManager = coordinator?.getSharedUserManager() {
            self.userManager = sharedUserManager
            print("Using shared UserManager")
        } else {
            print("Using local UserManager")
        }
        setupUI()
        setupBindings()
        loadUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("UserSelectionViewController viewWillAppear")
        print("Current user before refresh: \(userManager.currentUser?.name ?? userManager.currentUser?.email ?? "none") with ID: \(userManager.currentUser?.id.uuidString ?? "none")")
        // Refresh user list when view appears
        loadUsers()
    }
    
    // MARK: - Setup Methods
    override func setupUI() {
        view.backgroundColor = .systemBackground
        configureTableView()
        configureAddUserButton()
        configureTitleLabel()
        configureCloseButton()
        setupConstraints()
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UserProfileCell.self, forCellReuseIdentifier: "UserProfileCell")
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
    
    private func configureAddUserButton() {
        addUserButton.setTitle("Add New User", for: .normal)
        addUserButton.backgroundColor = .systemBlue
        addUserButton.setTitleColor(.white, for: .normal)
        addUserButton.layer.cornerRadius = 8
        addUserButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addUserButton.addTarget(self, action: #selector(addUserButtonTapped), for: .touchUpInside)
        addUserButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addUserButton)
    }
    
    private func configureTitleLabel() {
        titleLabel.text = "Switch User"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
    }
    
    private func configureCloseButton() {
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
    }
    
    internal override func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addUserButton.topAnchor, constant: -20),
            
            // Add user button
            addUserButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addUserButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addUserButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addUserButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBindings() {
        // Bind user list updates
        if let userManager = userManager as? UserManager {
            userManager.$allUsers
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.tableView.reloadData()
                }
                .store(in: &cancellables)
            
            // Bind loading state
            userManager.$isLoading
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isLoading in
                    self?.updateUIForLoading(isLoading)
                }
                .store(in: &cancellables)
        }
    }
    
    private func updateUIForLoading(_ isLoading: Bool) {
        addUserButton.isEnabled = !isLoading
        addUserButton.alpha = isLoading ? 0.6 : 1.0
    }
    
    private func loadUsers() {
        Task {
            await userManager.loadAllUsers()
            await MainActor.run {
                print("=== USER LIST DEBUG ===")
                print("Total users loaded: \(self.userManager.allUsers.count)")
                for (index, user) in self.userManager.allUsers.enumerated() {
                    let isCurrent = user.id == self.userManager.currentUser?.id
                    print("User \(index): \(user.name ?? user.email) (ID: \(user.id.uuidString), Current: \(isCurrent))")
                }
                print("Current user: \(self.userManager.currentUser?.name ?? self.userManager.currentUser?.email ?? "none") (ID: \(self.userManager.currentUser?.id.uuidString ?? "none"))")
                print("=======================")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func addUserButtonTapped(_ sender: Any) {
        presentSignupViewController()
    }
    
    private func presentSignupViewController() {
        guard let signupViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController else {
            showAlert(title: "Error", message: "Could not load signup screen")
            return
        }
        
        signupViewController.coordinator = self.coordinator
        signupViewController.signupDelegate = self
        let navigationController = UINavigationController(rootViewController: signupViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    @objc private func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - SignupDelegate
extension UserSelectionViewController: SignupDelegate {
    func signupCompleted() {
        // Refresh user list when signup is completed
        loadUsers()
    }
}

// MARK: - UITableViewDataSource
extension UserSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = userManager.allUsers.count
        print("TableView numberOfRowsInSection: \(count)")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserProfileCell", for: indexPath) as! UserProfileCell
        let user = userManager.allUsers[indexPath.row]
        let isCurrentUser = user.id == userManager.currentUser?.id
        print("Configuring cell for user: \(user.name ?? user.email), isCurrentUser: \(isCurrentUser)")
        cell.configure(with: user, isCurrentUser: isCurrentUser)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension UserSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = userManager.allUsers[indexPath.row]
        print("User tapped: \(user.name ?? user.email) with ID: \(user.id.uuidString)")
        print("Current user: \(userManager.currentUser?.name ?? userManager.currentUser?.email ?? "none") with ID: \(userManager.currentUser?.id.uuidString ?? "none")")
        
        // Don't switch if it's already the current user
        guard user.id != userManager.currentUser?.id else { 
            print("User is already current user, not switching")
            return 
        }
        
        print("Attempting to switch to user: \(user.name ?? user.email)")
        
        Task {
            do {
                try await userManager.switchToUser(user.id.uuidString)
                await MainActor.run {
                    print("Switch successful, dismissing")
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    print("Switch failed with error: \(error)")
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let user = userManager.allUsers[indexPath.row]
        
        showConfirmationAlert(title: "Remove User", message: "Are you sure you want to remove \(user.name ?? user.email)? This will delete all their data.") {
            Task {
                do {
                    try await self.userManager.removeUser(user.id.uuidString)
                    await MainActor.run {
                        self.showAlert(title: "Success", message: "Removed \(user.name ?? user.email)")
                    }
                } catch {
                    await MainActor.run {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
    }
}

// MARK: - UserProfileCell
class UserProfileCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let activeIndicator = UIView()
    private let stackView = UIStackView()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Configure profile image
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure labels
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        
        emailLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        
        // Configure active indicator
        activeIndicator.backgroundColor = .systemGreen
        activeIndicator.layer.cornerRadius = 4
        activeIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(emailLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(profileImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(activeIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),
            
            stackView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: activeIndicator.leadingAnchor, constant: -12),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            activeIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            activeIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activeIndicator.widthAnchor.constraint(equalToConstant: 8),
            activeIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    // MARK: - Configuration
    func configure(with user: User, isCurrentUser: Bool) {
        nameLabel.text = user.name ?? user.email
        emailLabel.text = user.email
        activeIndicator.isHidden = !isCurrentUser
        
        if isCurrentUser {
            backgroundColor = .systemBlue.withAlphaComponent(0.1)
        } else {
            backgroundColor = .systemBackground
        }
    }
} 