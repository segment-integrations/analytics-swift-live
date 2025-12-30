//
//  SceneDelegate.swift
//  UIKitNavExample
//
//  Created by Brandon Sneed on 12/30/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Create tab bar controller
        let tabBarController = UITabBarController()
        
        // Navigation tab
        let navigationVC = NavigationTestViewController()
        let navNavController = UINavigationController(rootViewController: navigationVC)
        navNavController.tabBarItem = UITabBarItem(title: "Navigation", image: UIImage(systemName: "arrow.triangle.turn.up.right.diamond"), tag: 0)
        
        // Sheets tab
        let sheetsVC = SheetTestViewController()
        let sheetsNavController = UINavigationController(rootViewController: sheetsVC)
        sheetsNavController.tabBarItem = UITabBarItem(title: "Sheets", image: UIImage(systemName: "square.stack"), tag: 1)
        
        // Settings tab
        let settingsVC = SettingsViewController()
        let settingsNavController = UINavigationController(rootViewController: settingsVC)
        settingsNavController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 2)
        
        tabBarController.viewControllers = [navNavController, sheetsNavController, settingsNavController]
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
