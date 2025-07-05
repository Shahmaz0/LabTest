//
//  AppCoordinator.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import UIKit

// MARK: - Coordinator Protocol
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController? { get set }
    func start()
}

// MARK: - App Coordinator
final class AppCoordinator: Coordinator {
    weak var navigationController: UINavigationController?
    private let window: UIWindow
    private var userManager: (any UserManagerProtocol)?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        // Check if user is already logged in
        Task {
            do {
                let authService = AuthService()
                if let _ = try await authService.getCurrentUser() {
                    await MainActor.run {
                        self.showMainInterface()
                    }
                } else {
                    await MainActor.run {
                        self.showLoginInterface()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showLoginInterface()
                }
            }
        }
    }
    
    @MainActor private func showLoginInterface() {
        guard let loginViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else {
            fatalError("LoginViewController not found in storyboard")
        }
        
        loginViewController.coordinator = self
        let navigationController = UINavigationController(rootViewController: loginViewController)
        self.navigationController = navigationController
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    @MainActor private func showMainInterface() {
        guard let tabBarController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "tabbarVC") as? UITabBarController else {
            fatalError("TabBarController not found in storyboard")
        }
        
        // Get shared user manager and load current user
        let sharedUserManager = getSharedUserManager()
        
        // Load current user data
        Task {
            await sharedUserManager.loadAllUsers()
        }
        
        // Set up coordinators for tab bar items
        if let homeViewController = tabBarController.viewControllers?.first as? HomeViewController {
            homeViewController.coordinator = self
            homeViewController.userManager = sharedUserManager
        }
        
        if let profileViewController = tabBarController.viewControllers?.last as? ProfileViewController {
            profileViewController.coordinator = self
            profileViewController.userManager = sharedUserManager
        }
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    @MainActor func showSignup() {
        guard let signupViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "SignupViewController") as? SignupViewController else {
            fatalError("SignupViewController not found in storyboard")
        }
        
        signupViewController.coordinator = self
        navigationController?.pushViewController(signupViewController, animated: true)
    }
    
    @MainActor func showMainInterfaceAfterAuth() {
        showMainInterface()
    }
    
    @MainActor func logout() {
        showLoginInterface()
    }
    
    // MARK: - Shared Services
    func getSharedUserManager() -> any UserManagerProtocol {
        if userManager == nil {
            userManager = UserManager()
        }
        return userManager!
    }
} 
