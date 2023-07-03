//
//  JukeboxApp.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 13/10/21.
//  Modified by Bryan Yung.
//

import SwiftUI
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    @AppStorage("viewedOnboarding") var viewedOnboarding: Bool = false
    @AppStorage("showTitle") private var showTitle: Bool = true
    @AppStorage("showArtist") private var showArtist: Bool = false
    @AppStorage("ignoreParentheses") private var ignoreParentheses = false
    @AppStorage("dynamicResizing") private var dynamicResizing = true
    @AppStorage("statusBarButtonLimit") private var statusBarButtonLimit = Constants.StatusBar.defaultStatusBarButtonLimit
    @StateObject var contentViewVM = ContentViewModel()
    static private(set) var instance: AppDelegate! = nil
    private var statusBarItem: NSStatusItem!
    private var statusBarMenu: NSMenu!
    private var popover: NSPopover!
    private var preferencesWindow: PreferencesWindow!
    private var onboardingWindow: OnboardingWindow!
    
    // For dynamic status bar item sizing
    private var ignoreForceHiddenNotifs: Bool = false  // set to true when trying different sizes of status bar items
    private var currentStringWidth: CGFloat = 0
    private var currentForceHiddenRestrictedWidth: CGFloat = Constants.Number.infinity
    private let statusBarItemResizeDecrement: CGFloat = 48  // how much Jukebox will try to decrease the size of the status bar item to make it fit
    
    private var currentTrackTitle: String = ""
    private var currentTrackArtist: String = ""
    private var currentIsPlaying: Bool = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // So AppDelegate object can be accessed outside of this class
        AppDelegate.instance = self
        
        // Onboarding
        guard viewedOnboarding else {
            showOnboarding()
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        // Setup
        setupContentView()
        setupStatusBar()
        
        // Add observer to listen to when track changes to update the title in the menu bar
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusBarItemTitleWithNotif),
            name: NSNotification.Name("TrackChanged"),
            object: nil)
        
        NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification, object: statusBarItem.button!.window, queue: nil) { _ in
//            print("notif")
//
//            // Return if ignoring notif
//            print(self.ignoreForceHiddenNotifs ? "ignored" : "")
            guard !self.ignoreForceHiddenNotifs else { return }
            // Return if manually set to invisible
            guard self.statusBarItem.isVisible else { return }
            
//            let forceHidden = self.statusBarItem.button!.window?.occlusionState.contains(.visible) == false

//            print("Force-hidden:", forceHidden)
            self.updateStatusBarItem()
            
        }
                
    }
    
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return true
        }

        showPreferences(nil)

        return false
    }
    
    // MARK: - Setup
    
    private func setupContentView() {
        let frameSize = NSSize(width: 272, height: 350)
        
        // Initialize ContentView
        let hostedContentView = NSHostingView(rootView: ContentView(contentViewVM: contentViewVM))
        hostedContentView.frame = NSRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        // Initialize Popover
        popover = NSPopover()
        popover.contentSize = frameSize
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostedContentView
        popover.contentViewController?.view.window?.makeKey()
    }
    
    private func setupStatusBar() {
        // Initialize Status Bar Menu
        statusBarMenu = NSMenu()
        statusBarMenu.delegate = self
        let hostedAboutView = NSHostingView(rootView: AboutView())
        hostedAboutView.frame = NSRect(x: 0, y: 0, width: 220, height: 70)
        let aboutMenuItem = NSMenuItem()
        aboutMenuItem.view = hostedAboutView
        statusBarMenu.addItem(aboutMenuItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        let updates = NSMenuItem(
            title: "Check for updates...",
            action: #selector(SUUpdater.checkForUpdates(_:)),
            keyEquivalent: "")
        updates.target = SUUpdater.shared()
        statusBarMenu.addItem(updates)
        statusBarMenu.addItem(
            withTitle: "Preferences...",
            action: #selector(showPreferences),
            keyEquivalent: ",")
        statusBarMenu.addItem(
            withTitle: "Quit Jukebox",
            action: #selector(NSApplication.terminate),
            keyEquivalent: "q")
        
        // Initialize Status Bar Item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Initialize the Status Bar Item Button properties
        if let statusBarItemButton = statusBarItem.button {
            
            // Add bar animation to Status Bar Item Button
            let barAnimation = StatusBarAnimation(
                menubarAppearance: statusBarItemButton.effectiveAppearance,
                menubarHeight: statusBarItemButton.bounds.height, isPlaying: false)
            statusBarItemButton.addSubview(barAnimation)
            
            // Add default marquee text
            let marqueeText = MenuMarqueeText(
                text: "",
                menubarBounds: statusBarItemButton.bounds,
                menubarAppearance: statusBarItemButton.effectiveAppearance)
            statusBarItemButton.addSubview(marqueeText)
            
            statusBarItemButton.frame = NSRect(x: 0, y: 0, width: barAnimation.bounds.width + 2*Constants.StatusBar.statusBarButtonPadding, height: statusBarItemButton.bounds.height)
            marqueeText.menubarBounds = statusBarItemButton.bounds
            
            // Set Status Bar Item Button click action
            statusBarItemButton.action = #selector(didClickStatusBarItem)
            statusBarItemButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
        }
        
        // Add observer to listen for status bar appearance changes
        statusBarItem.addObserver(
            self,
            forKeyPath: "button.effectiveAppearance.name",
            options: [ .new, .initial ],
            context: nil)
    }
    
    // MARK: - Status Bar Handlers
    
    // Handle left or right click of Status Bar Item
    @objc func didClickStatusBarItem(_ sender: AnyObject?) {

        guard let event = NSApp.currentEvent else { return }
        
        switch event.type {
        case .rightMouseUp:
            statusBarItem.menu = statusBarMenu
            statusBarItem.button?.performClick(nil)
            
        default:
            togglePopover(statusBarItem.button)
        }
        
    }
    
    // Set menu to nil when closed so popover is re-enabled
    func menuDidClose(_: NSMenu) {
        statusBarItem.menu = nil
    }
    
    @objc func closePopover(_ sender: NSStatusBarButton?) {
        guard let statusBarItemButton = sender else { return }
        
        if popover.isShown {
            popover.performClose(statusBarItemButton)
        }
    }
    
    // Toggle open and close of popover
    @objc func togglePopover(_ sender: NSStatusBarButton?) {
        
        guard let statusBarItemButton = sender else { return }
        
        if popover.isShown {
            popover.performClose(statusBarItemButton)
        } else {
            popover.show(relativeTo: statusBarItemButton.bounds, of: statusBarItemButton, preferredEdge: .minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
    }
    
    // Updates the title of the status bar with the currently playing track
    @objc func updateStatusBarItemTitleWithNotif(_ notification: NSNotification) {
        
        // Get track data from notification
        guard let trackTitle = notification.userInfo?["title"] as? String else { return }
        guard let trackArtist = notification.userInfo?["artist"] as? String else { return }
        guard let isPlaying = notification.userInfo?["isPlaying"] as? Bool  else { return }
        
        currentTrackTitle = trackTitle
        currentTrackArtist = trackArtist
        currentIsPlaying = isPlaying
                
        updateStatusBarItem(updateIcon: true, updateTitle: true)
        
    }
    
    @objc func updateStatusBarItemIcon() {

        // Get status item button (whole status bar item)
        guard let button = statusBarItem.button else { return }

        // Get animation/icon part of status bar item
        guard let barAnimation = button.subviews[0] as? StatusBarAnimation else { return }
        // Get text part of status bar item
        guard let marqueeText = button.subviews[1] as? MenuMarqueeText else { return }

        // Update bar animation
        let togglePlayPause = barAnimation.isPlaying != currentIsPlaying
        if togglePlayPause { barAnimation.isPlaying = currentIsPlaying }

        // Update text
        if marqueeText.text != "" { marqueeText.text = "" }

        // Set dimensions of menu bar extra to only animation
        let width = barAnimation.bounds.width + 2*Constants.StatusBar.statusBarButtonPadding
        let height = button.bounds.height

        if button.frame.width != width || button.frame.height != height {
            button.frame = NSRect(x: 0, y: 0, width: width, height: height)
        }

        perform(#selector(stopIgnoringForceNotifs), with: nil, afterDelay: 0.5)

    }
    
    // Updates the status bar item, handles icon changes, text changes, resizing
    @objc func updateStatusBarItem(showOnlyIcon: Bool = false, updateIcon: Bool = false, updateTitle: Bool = false, forceHiddenRestrictedWidth: CGFloat = Constants.Number.infinity) {
        
        // Get status item button (whole status bar item)
        guard let button = statusBarItem.button else { return }
        guard let marqueeText = button.subviews[1] as? MenuMarqueeText else { return }
        
        // if paused or unpaused, not triggered when resized
        if updateIcon {
            // Get animation/icon part of status bar item
            guard let barAnimation = button.subviews[0] as? StatusBarAnimation else { return }
            
            if barAnimation.isPlaying != currentIsPlaying { barAnimation.isPlaying = currentIsPlaying }
        }
        
        // only if text changed, not triggered when resized
        if updateTitle || showOnlyIcon {
            // Calculate updated display text
            let text = calculateUpdatedDisplayText(showOnlyIcon: showOnlyIcon)
            
            // Set Marquee text with new track data (or different data on user preference change)
            if marqueeText.text != text { marqueeText.text = text }
            
            currentStringWidth = text.stringWidth(with: Constants.StatusBar.marqueeFont)
        }
        
        let width = calculateStatusBarItemWidth(showOnlyIcon: showOnlyIcon, stringWidth: currentStringWidth, forceHiddenRestrictedWidth: forceHiddenRestrictedWidth)
        let height = button.bounds.height
        
        print("trying with:", width, height)
        
//        if width >= currentForceHiddenRestrictedWidth {
//            return
//        }
        
        button.frame = NSRect(x: 0, y: 0, width: width, height: height)
        marqueeText.menubarBounds = button.bounds
        
        
        // Decrement all the way to 0 if dynamic resizing is off
        ignoreForceHiddenNotifs = true
                        
        let decrement = dynamicResizing ? statusBarItemResizeDecrement : width
        
        perform(#selector(downsizeStatusBarItemTitleIfNeeded), with: [button, width, decrement] as [Any], afterDelay: 0.5)
        
        currentForceHiddenRestrictedWidth = forceHiddenRestrictedWidth
        
    }
    
    @objc func calculateUpdatedDisplayText(showOnlyIcon: Bool = false) -> String {
        var text = ""
        
        if showOnlyIcon { return text }
        // Only update text if text is showing
        if (showTitle) {
            text += ignoreParentheses ? currentTrackTitle.getWithoutParentheses() : currentTrackTitle
        }
        if (showArtist) {
            if !text.isEmpty { text += " • " }
            text += ignoreParentheses ? currentTrackArtist.getWithoutParentheses() : currentTrackArtist
        }
        return text
    }
    
    @objc func calculateStatusBarItemWidth(showOnlyIcon: Bool = false, stringWidth: CGFloat = 0, forceHiddenRestrictedWidth: CGFloat = Constants.Number.infinity) -> CGFloat {
        let animWidth = Constants.StatusBar.barAnimationWidth
        let padding = Constants.StatusBar.statusBarButtonPadding
        
        if showOnlyIcon {
            return animWidth + 2*padding
        } else {
            return min(animWidth + stringWidth + 3*padding,
                       statusBarButtonLimit == Constants.StatusBar.marqueeInfiniteWidth ? Constants.Number.infinity : floor(statusBarButtonLimit),
                       forceHiddenRestrictedWidth)
        }
    }
    
    @objc func downsizeStatusBarItemTitleIfNeeded(_ arg: NSArray) {
        let button: NSStatusBarButton = arg[0] as! NSStatusBarButton
        
        let lowerLimit = Constants.StatusBar.marqueeMinimumWidth
        let upperLimit: CGFloat = arg[1] as! CGFloat
        
        let decrement: CGFloat = arg[2] as! CGFloat
        let forceHidden = button.window?.occlusionState.contains(.visible) == false
                
        var newValue: CGFloat = upperLimit - upperLimit.truncatingRemainder(dividingBy: statusBarItemResizeDecrement)
        if newValue == upperLimit {
            newValue -= decrement
        }
        
        let showOnlyIcon = newValue < lowerLimit
        
        if forceHidden {
            updateStatusBarItem(showOnlyIcon: showOnlyIcon, forceHiddenRestrictedWidth: newValue)
        } else {
            stopIgnoringForceNotifs()
        }
    }
    
    @objc func stopIgnoringForceNotifs() {
        ignoreForceHiddenNotifs = false
    }
    
    // Called when the status bar appearance is changed to update bar animation color and marquee text color
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (keyPath == "button.effectiveAppearance.name") {
            
            // Get bar animation and marquee from status item button
            guard let barAnimation = statusBarItem.button?.subviews[0] as? StatusBarAnimation else { return }
            guard let marquee = statusBarItem.button?.subviews[1] as? MenuMarqueeText else { return }
            
            let appearance = statusBarItem.button?.effectiveAppearance.name
            
            // Update based on current menu bar appearance
            switch appearance {
            case NSAppearance.Name.vibrantDark:
                barAnimation.menubarIsDarkAppearance = true
                marquee.menubarIsDarkAppearance = true
            default:
                barAnimation.menubarIsDarkAppearance = false
                marquee.menubarIsDarkAppearance = false
            }
            
        }
        
    }
    
    // MARK: - Window Handlers
    
    // Open the preferences window
    @objc func showPreferences(_ sender: AnyObject?) {
        
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindow()
            let hostedPrefView = NSHostingView(rootView: PreferencesView(parentWindow: preferencesWindow))
            preferencesWindow.contentView = hostedPrefView
        }
        
        preferencesWindow.center()
        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    
    // Open the onboarding window
    private func showOnboarding() {
        if onboardingWindow == nil {
            onboardingWindow = OnboardingWindow()
            let hostedOnboardingView = NSHostingView(rootView: OnboardingView())
            onboardingWindow.contentView = hostedOnboardingView
        }
        
        onboardingWindow.center()
        onboardingWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    // Close the onboarding window
    @objc func finishOnboarding(_ sender: AnyObject) {
        setupContentView()
        setupStatusBar()
        onboardingWindow.close()
        self.onboardingWindow = nil
    }
    
}

// MARK: - SwiftUI App Entry Point

@main
struct JukeboxApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        // Required to hide window
        Settings {
            EmptyView()
        }
        
    }
    
}
