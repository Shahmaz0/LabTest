//
//  SignupViewController.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit
import Combine

final class SignupViewController: BaseViewController {

    // MARK: - Outlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    // MARK: - Properties
    private var viewModel: AuthViewModel!
    private var cancellables = Set<AnyCancellable>()
    weak var signupDelegate: SignupDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupBindings()
    }
    
    // MARK: - Setup Methods
    override func setupUI() {
        configureTextFields()
        configureSignupButton()
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
        nameTextField?.placeholder = "Full Name"
        nameTextField?.autocapitalizationType = .words
        nameTextField?.autocorrectionType = .no
        
        emailTextField?.placeholder = "Email"
        emailTextField?.keyboardType = .emailAddress
        emailTextField?.autocapitalizationType = .none
        emailTextField?.autocorrectionType = .no
        
        passwordTextField?.placeholder = "Password"
        passwordTextField?.isSecureTextEntry = true
    }
    
    private func configureSignupButton() {
        guard let signupButton = signupButton else { return }
        
        signupButton.setTitle("Sign Up", for: .normal)
        signupButton.backgroundColor = .systemBlue
        signupButton.setTitleColor(.white, for: .normal)
        signupButton.layer.cornerRadius = 8
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
                self?.showAlert(title: "Signup Failed", message: errorMessage)
            }
            .store(in: &cancellables)
        
        // Bind authentication state
        viewModel.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] (isAuthenticated: Bool) in
                // Notify delegate that signup is completed
                self?.signupDelegate?.signupCompleted()
                // Pop back to user selection
                self?.navigationController?.popViewController(animated: true)
                // Show success message after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.showAlert(title: "Success", message: "User account created successfully!")
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateUIForLoading(_ isLoading: Bool) {
        guard let signupButton = signupButton else { return }
        
        signupButton.isEnabled = !isLoading
        signupButton.alpha = isLoading ? 0.6 : 1.0
        
        if isLoading {
            signupButton.setTitle("Creating Account...", for: .normal)
        } else {
            signupButton.setTitle("Sign Up", for: .normal)
        }
    }
    
    // MARK: - Actions
    @IBAction func signupBtnClicked(_ sender: Any) {
        guard let name = nameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text else { return }
        
        viewModel.signUp(email: email, password: password, name: name)
    }
}
