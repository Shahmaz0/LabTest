//
//  BaseViewController.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit

// MARK: - Base View Controller
class BaseViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - Setup Methods (Override in subclasses)
    func setupUI() {
        // Override in subclasses
    }
    
    func setupConstraints() {
        // Override in subclasses
    }
    
    func setupActions() {
        // Override in subclasses
    }
    
    // MARK: - Common UI Methods
    func showLoading(_ show: Bool) {
        // Override in subclasses if needed
    }
    
    func showAlert(title: String, message: String, actions: [UIAlertAction] = []) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if actions.isEmpty {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        } else {
            actions.forEach { alert.addAction($0) }
        }
        
        present(alert, animated: true)
    }
    
    func showConfirmationAlert(title: String, message: String, confirmAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            confirmAction()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error) {
        let message = error.localizedDescription
        showAlert(title: "Error", message: message)
    }
} 