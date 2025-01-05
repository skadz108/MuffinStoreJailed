//
//  UIApplication+returnToHomeScreen.swift
//  feather
//
//  Created by Lakhan Lothiyi on 22/08/2024.
//

import Foundation
import UIKit

extension UIApplication {
    /// Returns from the foreground app to the home screen.
    func returnToHomeScreen() {
        LSApplicationWorkspace.default().openApplication(withBundleID: "com.apple.springboard")
        exit(0)
    }
}
