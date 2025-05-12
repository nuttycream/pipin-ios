//
//  LogView.swift
//  pipin
//
//  Created by bryan yao on 5/10/25.
//

import SwiftUI

struct LogsView: View {
    @Binding var showLogs: Bool
    var logs: [String]
    
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
            
            if logs.isEmpty {
                VStack {
                    Spacer()
                    Text("No logs available")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(logs, id: \.self) { log in
                            Text(log)
                                .foregroundColor(.white)
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}


