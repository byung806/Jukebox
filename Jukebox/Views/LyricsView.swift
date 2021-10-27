//
//  LyricsView.swift
//  Jukebox
//
//  Created by Sasindu Jayasinghe on 27/10/21.
//

import SwiftUI

struct LyricsView: View {
    
    @Binding var showingLyrics: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        // Close the lyrics view
                        showingLyrics = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .pressButtonStyle()
                    Spacer()
                }
                Spacer()
            }
            VStack(alignment: .center) {
                Text("Lyrics for the track...")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 20, weight: .bold))
            }
            .padding(22)
        }
        .padding()
    }
}