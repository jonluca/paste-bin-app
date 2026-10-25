//
//  AppDelegate.swift
//  PasteBin
//
//  Created by JonLuca De Caro on 12/28/16.
//  Copyright © 2016 JonLuca De Caro. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ErrorReporting.start()
        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // Set the status bar with white text on dark background.
    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.statusBarStyle = .lightContent // .default
        return true
    }

    // Guide from https://the-nerd.be/2015/09/30/add-3d-touch-quick-actions-tutorial/
    func application(_: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler _: @escaping (Bool) -> Void) {
        // 3D touch quick action for quick paste
        if shortcutItem.type == "com.jonluca.pastebinapp.quickpaste" {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc: ViewController = mainStoryboard.instantiateViewController(withIdentifier: "mainView") as! ViewController
            vc.quickSubmit(self)
            let alertController = UIAlertController(title: "Success!", message: "\nSuccesfully copied to clipboard!", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { _ in
                // handle response here.
            }
            alertController.addAction(OKAction)
            window?.rootViewController?.present(alertController, animated: true) {}
        }
    }
}
