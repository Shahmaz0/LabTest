//
//  ProfileViewController.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit
import Combine

final class ProfileViewController: BaseViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var switchUserButton: UIButton!
    
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
        configureProfileImage()
        configureLabels()
        configureButtons()
    }
    
    // MARK: - Private Methods
    private func configureProfileImage() {
        profileImageView.layer.cornerRadius = 50
        profileImageView.clipsToBounds = true
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
    }
    
    private func configureLabels() {
        userNameLabel.text = "Loading..."
        userNameLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        userNameLabel.textAlignment = .center
        
        userEmailLabel.text = ""
        userEmailLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        userEmailLabel.textColor = .systemGray
        userEmailLabel.textAlignment = .center
    }
    
    private func configureButtons() {
        logoutButton?.setTitle("Logout", for: .normal)
        logoutButton?.backgroundColor = .systemRed
        logoutButton?.setTitleColor(.white, for: .normal)
        logoutButton?.layer.cornerRadius = 8
        logoutButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        switchUserButton?.setTitle("Switch User", for: .normal)
        switchUserButton?.backgroundColor = .systemBlue
        switchUserButton?.setTitleColor(.white, for: .normal)
        switchUserButton?.layer.cornerRadius = 8
        switchUserButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
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
            userEmailLabel.text = ""
            return
        }
        
        userNameLabel.text = currentUser.name ?? currentUser.email
        userEmailLabel.text = currentUser.email
    }
    
    private func performLogout() {
        Task {
            do {
                try await authService.signOut()
                await MainActor.run {
                    coordinator?.logout()
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Logout Error", message: "Failed to logout. Please try again.")
                    print("Logout error: \(error)")
                }
            }
        }
    }
    
    private func showUserSelection() {
        let userSelectionVC = UserSelectionViewController(userManager: userManager)
        userSelectionVC.modalPresentationStyle = .fullScreen
        present(userSelectionVC, animated: true)
    }
    
    // MARK: - Actions
    @IBAction func logoutButtonTapped(_ sender: Any) {
        showConfirmationAlert(title: "Logout", message: "Are you sure you want to logout?") {
            self.performLogout()
        }
    }
    
    @IBAction func switchUserButtonTapped(_ sender: Any) {
        showUserSelection()
    }
} 