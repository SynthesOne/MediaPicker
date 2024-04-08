//
//  AppDelegate.swift
//  MediaPickerExpample
//
//  Created by Валентин Панчишен on 05.04.2024.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let strongWindow = UIWindow(frame: UIScreen.main.bounds)
        
        strongWindow.rootViewController = ViewController()
        window = strongWindow
        strongWindow.makeKeyAndVisible()
        
        return true
    }
}

