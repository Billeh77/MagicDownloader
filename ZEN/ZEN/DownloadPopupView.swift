//
//  DownloadPopupView.swift
//  ZEN
//
//  Created by Layanne El Assaad on 2/28/25.
//

import SwiftUI

struct DownloadPopupView: View {
    var file: URL

    var body: some View {
        VStack {
            Text("New Download Detected!")
                .font(.headline)
                .padding()

            Text(file.lastPathComponent)
                .font(.subheadline)
                .padding()

            Button("Open Downloads Folder") {
                NSWorkspace.shared.open(file)
            }
            .padding()
        }
        .frame(width: 250, height: 150)
    }
}
