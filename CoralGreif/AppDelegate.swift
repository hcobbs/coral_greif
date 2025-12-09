//
//  AppDelegate.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var coordinator: AppCoordinator?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        let coordinator = AppCoordinator(window: window)
        self.coordinator = coordinator
        coordinator.start()

        return true
    }
}
