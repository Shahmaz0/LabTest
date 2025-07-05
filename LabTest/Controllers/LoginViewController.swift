//
//  LoginViewController.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit
import Combine

final class LoginViewController: BaseViewController {

    // MARK: - Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Properties
    private var viewModel: AuthViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupBindings()
    }
    
    // MARK: - Setup Methods
    override func setupUI() {
        configureTextFields()
        configureLoginButton()
        setupKeyboardDismissal()
    }
    
    override func setupActions() {
        // Bindings are handled in setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupViewModel() {
        let sharedUserManager = coordinator?.getSharedUserManager() ?? UserManager()
        viewModel = AuthViewModel(userManager: sharedUserManager)
    }
    
    private func configureTextFields() {
        emailTextField?.placeholder = "Email"
        emailTextField?.keyboardType = .emailAddress
        emailTextField?.autocapitalizationType = .none
        emailTextField?.autocorrectionType = .no
        
        passwordTextField?.placeholder = "Password"
        passwordTextField?.isSecureTextEntry = true
    }
    
    private func configureLoginButton() {
        guard let loginButton = loginButton else { return }
        
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
    }
    
    private func setupBindings() {
        // Bind loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateUIForLoading(isLoading)
            }
            .store(in: &cancellables)
        
        // Bind error messages
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "Login Failed", message: errorMessage)
            }
            .store(in: &cancellables)
        
        // Bind authentication state
        viewModel.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] (isAuthenticated: Bool) in
                self?.coordinator?.showMainInterfaceAfterAuth()
            }
            .store(in: &cancellables)
    }
    
    private func updateUIForLoading(_ isLoading: Bool) {
        guard let loginButton = loginButton else { return }
        
        loginButton.isEnabled = !isLoading
        loginButton.alpha = isLoading ? 0.6 : 1.0
        
        if isLoading {
            loginButton.setTitle("Logging in...", for: .normal)
        } else {
            loginButton.setTitle("Login", for: .normal)
        }
    }
    
    // MARK: - Actions
    @IBAction func loginBtnClicked(_ sender: Any) {
        guard let email = emailTextField.text,
              let password = passwordTextField.text else { return }
        
        viewModel.signIn(email: email, password: password)
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        coordinator?.showSignup()
    }
}
