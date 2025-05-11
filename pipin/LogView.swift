//
//  LogView.swift
//  pipin
//
//  Created by bryan yao on 5/10/25.
//

import SwiftUI

struct LogsView: View {
    @Binding var showLogs: Bool

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showLogs = false
                }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
                Text("Logs")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Spacer() // balances the layout
            }
            .background(Color.gray.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("[Log] GPIO 23 failed: Not Initialized")
                    Text("[Log] GPIO 2 set to HIGH")
                    Text("[Log] Queue started")
                    Text("[Log] Queue stopped")

                    // More log entries here...
                }
                .padding()
                .foregroundColor(.white)
                .font(.system(size: 14, design: .monospaced))
            }

            Spacer()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
