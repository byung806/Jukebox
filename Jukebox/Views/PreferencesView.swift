//
//  PreferencesView.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 29/10/21.
//  Modified by Bryan Yung.
//

import SwiftUI
import LaunchAtLogin

struct PreferencesView: View {
    
    private weak var parentWindow: PreferencesWindow!
    
    @AppStorage("visualizerStyle") private var visualizerStyle = VisualizerStyle.albumArt
    @AppStorage("connectedApp") private var connectedApp = ConnectedApps.spotify
    @AppStorage("showTitle") private var showTitle = true
    @AppStorage("showArtist") private var showArtist = false
    @AppStorage("marqueeAnimationDelay") private var marqueeAnimationDelay = 3
    @AppStorage("ignoreParentheses") private var ignoreParentheses = false
    @AppStorage("dynamicResizing") private var dynamicResizing = true
    @AppStorage("statusBarButtonLimit") private var statusBarButtonLimit = Constants.StatusBar.defaultStatusBarButtonLimit
    @State private var alertTitle = Text("Title")
    @State private var alertMessage = Text("Message")
    @State private var showingAlert = false

    private var name: Text {
        Text(connectedApp.localizedName)
    }
    
    private func updateStatusBarItem(updateIcon: Bool = false, updateTitle: Bool = false) {
        AppDelegate.instance.updateStatusBarItem(updateIcon: updateIcon, updateTitle: updateTitle)
    }
    
    init(parentWindow: PreferencesWindow) {
        self.parentWindow = parentWindow
    }
    
    // MARK: - Main Body
    var body: some View {
        
        VStack(spacing: 0) {
            ZStack {
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                closeButton
                appInfo
            }
            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60, alignment: .center)
            .offset(y: 1) // Looked like it was off center
            
            Divider()
            
            preferencePanes
        }
        .ignoresSafeArea()
        
    }
    
    // MARK: - Close Button
    private var closeButton: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    parentWindow.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.leading, 12)
                Spacer()
            }
            Spacer()
        }
    }
    
    // MARK: - App Info
    private var appInfo: some View {
        HStack(spacing: 8) {
            HStack {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text("Jukebox").font(.headline)
                    Text("Version \(Constants.AppInfo.appVersion ?? "?")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading)
            
            Spacer()
            
            HStack {
                Button {
                    NSWorkspace.shared.open(Constants.AppInfo.forkedRepo)
                } label: {
                    Text("GitHub (this fork)").font(.system(size: 12))
                }
                .buttonStyle(LinkButtonStyle())
                
                Button {
                    NSWorkspace.shared.open(Constants.AppInfo.originalRepo)
                } label: {
                    Text("GitHub (original)").font(.system(size: 12))
                }
                .buttonStyle(LinkButtonStyle())
                
                Button {
                    NSWorkspace.shared.open(Constants.AppInfo.website)
                } label: {
                    Text("Website").font(.system(size: 12))
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
        .padding(.horizontal, 18)
    }
    
    // MARK: - Preference Panes
    private var preferencePanes: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // General Pane
            VStack(alignment: .leading) {
                Text("General")
                    .font(.title2)
                    .fontWeight(.semibold)
                LaunchAtLogin.Toggle()
                HStack {
                    Picker("Connect Jukebox to", selection: $connectedApp) {
                        ForEach(ConnectedApps.allCases, id: \.self) { value in
                            Text(value.localizedName).tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    Button {
                        let consent = Helper.promptUserForConsent(for: connectedApp == .spotify ? Constants.Spotify.bundleID : Constants.AppleMusic.bundleID)
                        switch consent {
                        case .closed:
                            alertTitle = Text("\(name) is not open")
                            alertMessage = Text("Please open \(name) to enable permissions")
                        case .granted:
                            alertTitle = Text("Permission granted for \(name)")
                            alertMessage = Text("Start playing a song!")
                        case .notPrompted:
                            return
                        case .denied:
                            alertTitle = Text("Permission denied")
                            alertMessage = Text("Please go to System Preferences > Security & Privacy > Privacy > Automation, and check \(name) under Jukebox")
                        }
                        showingAlert = true
                    } label: {
                        Image(systemName: "person.fill.questionmark")
                    }
                    .buttonStyle(.borderless)
                    .alert(isPresented: $showingAlert) {
                        Alert(title: alertTitle, message: alertMessage, dismissButton: .default(Text("Got it!")))
                    }
                    
                }
            }
            .padding()
            
            Divider()
            
            // Menu Bar Display Pane
            VStack(alignment: .leading) {
                Text("Menu Bar Display")
                    .font(.title2)
                    .fontWeight(.semibold)
                HStack() {
                    Text("Maximum Width")
                    Slider(value: $statusBarButtonLimit,
                           in: 30...500,
                           onEditingChanged: { editing in
                        updateStatusBarItem()
                    }
                    )
                    Text(statusBarButtonLimit == 500 ? "Infinite" : String(format: "%.0f px", statusBarButtonLimit))
                }
                HStack() {
                    Text("Show")
                    Toggle("Title", isOn: $showTitle).onChange(of: showTitle) { _ in
                        updateStatusBarItem(updateTitle: true)
                    }
                    Toggle("Artist", isOn: $showArtist).onChange(of: showArtist) { _ in
                        updateStatusBarItem(updateTitle: true)
                    }
                }
                HStack() {
                    Text("Animation Delay")
                    TextField("",
                              value: $marqueeAnimationDelay,
                              formatter: NumberFormatter()).disabled(true).foregroundColor(.black).frame(width: 50)
                    Stepper {
                    } onIncrement: {
                        marqueeAnimationDelay = min(10, marqueeAnimationDelay + 1)
                    } onDecrement: {
                        marqueeAnimationDelay = max(0, marqueeAnimationDelay - 1)
                    }
                }
                Toggle("Ignore Parentheses", isOn: $ignoreParentheses).onChange(of: ignoreParentheses) { _ in
                    updateStatusBarItem(updateTitle: true)
                }
                Toggle("Dynamic Resizing (Experimental)", isOn: $dynamicResizing).onChange(of: dynamicResizing) { _ in
                    updateStatusBarItem(updateTitle: true)
                }
                
            }
            .padding()
            
            Divider()
            
            // Visualizer Pane
            VStack(alignment: .leading) {
                Text("Background")
                    .font(.title2)
                    .fontWeight(.semibold)
                Picker("Style", selection: $visualizerStyle) {
                    ForEach(VisualizerStyle.allCases, id: \.self) { value in
                        Text(value.localizedName).tag(value)
                    }
                }
            }
            .padding()
            
        }
    }
    
}
