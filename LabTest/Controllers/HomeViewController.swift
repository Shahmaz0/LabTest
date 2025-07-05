//
//  HomeViewController.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit
import Combine

final class HomeViewController: BaseViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    
    // MARK: - Properties
    private let authService: AuthProtocol
    var userManager: any UserManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(authService: AuthProtocol = AuthService(), userManager: any UserManagerProtocol) {
        self.authService = authService
        self.userManager = userManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.authService = AuthService()
        self.userManager = UserManager()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserManagerBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentUserData()
    }
    
    // MARK: - Setup Methods
    override func setupUI() {
        configureLabels()
    }
    
    // MARK: - Private Methods
    private func configureLabels() {
        welcomeLabel.text = "Welcome"
        welcomeLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        welcomeLabel.textAlignment = .center
        
        userNameLabel.text = "Loading..."
        userNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        userNameLabel.textAlignment = .center
        userNameLabel.textColor = .systemBlue
    }
    
    private func setupUserManagerBindings() {
        guard let userManager = userManager as? UserManager else { return }
        
        // Observe current user changes
        userManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUserDisplay()
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentUserData() {
        Task {
            await userManager.loadAllUsers()
            await MainActor.run {
                self.updateUserDisplay()
            }
        }
    }
    
    private func updateUserDisplay() {
        guard let userManager = userManager as? UserManager,
              let currentUser = userManager.currentUser else {
            userNameLabel.text = "No user"
            return
        }
        
        userNameLabel.text = currentUser.name ?? currentUser.email
        userNameLabel.textColor = .systemBlue
    }
} 