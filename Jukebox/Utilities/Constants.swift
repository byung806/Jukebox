//
//  Constants.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 6/11/21.
//  Modified by Bryan Yung.
//

import Foundation
import AppKit

enum Constants {
    
    enum AppInfo {
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        static let originalRepo = URL(string: "https://github.com/Jaysce/Jukebox")!
        static let forkedRepo = URL(string: "https://github.com/byung806/Jukebox")!
        static let website = URL(string: "https://jaysce.dev/projects/jukebox")!
    }
    
    enum StatusBar {
        static let barAnimationWidth: CGFloat = 14
        static let barAnimationHeight: CGFloat = 10
        static let barWidth: CGFloat = 2
        static let marqueeFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        static let marqueeAnimationSpacer: CGFloat = 16              // space between repeating title in animatino
        static let marqueeAnimationDelay: CGFloat = 3                // time in seconds between animations
        static let marqueeMinimumWidth: CGFloat = 48                 // absolute minimum width before text is hidden entirely
        static let marqueeInfiniteWidth: CGFloat = 500               // constant to represent infinite in preferences
        static let defaultStatusBarButtonLimit: CGFloat = 300        // absolute maximum width text can have
        static let statusBarButtonPadding: CGFloat = 10               // padding between elements in status bar item
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
