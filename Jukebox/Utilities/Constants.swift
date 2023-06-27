//
//  Constants.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 6/11/21.
//

import Foundation
import AppKit

enum Constants {
    
    enum AppInfo {
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        static let repo = URL(string: "https://github.com/Jaysce/Jukebox")!
        static let website = URL(string: "https://jaysce.dev/projects/jukebox")!
    }
    
    enum StatusBar {
        static let marqueeFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        static let marqueeAnimationSpacer: CGFloat = 16
        static let marqueeAnimationDelay: CGFloat = 3
        static let barAnimationWidth: CGFloat = 14
        static let marqueeWidthBeforeHidden: CGFloat = 30
        static let defaultStatusBarButtonLimit: CGFloat = 110
        static let statusBarButtonPadding: CGFloat = 8
    }
    
    enum Number {
        static let infinity: CGFloat = CGFloat.greatestFiniteMagnitude
    }
    
    enum Spotify {
        static let name = "Spotify"
        static let bundleID = "com.spotify.client"
        static let notification = "\(bundleID).PlaybackStateChanged"
    }
    
    enum AppleMusic {
        static let name = "Apple Music"
        static let bundleID = "com.apple.Music"
        static let notification = "\(bundleID).playerInfo"
    }
    
}
