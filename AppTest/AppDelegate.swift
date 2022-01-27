//
//  AppDelegate.swift
//  AppTest
//
//

import NMAKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties
    private let appId = "appId"
    private let appCode = "appCode"
    private let licenseKey = "licenseKey"

    var window: UIWindow?

    // MARK: - Lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NMAApplicationContext.setAppId(appId, appCode: appCode, licenseKey: licenseKey)
        return true
    }
}

