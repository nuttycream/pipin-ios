//
//  QueueView.swift
//  pipin
//
//  Created by John on 5/11/25.
//

import SwiftUI

struct QueueView: View {
    @EnvironmentObject var connectionManager: PipinManager
    
    @State private var selectedAction = "Set Low"
    @State private var selectedPin = "0"
    @State private var delayValue = "1000"
    
    @State private var queue: [(String, String)] = []
    @State private var loop = false
    
    @State private var statusMessage: String? = nil
    
    let actions = [
        "Set Low",
        "Set High",
        "Delay",
        "Wait For High",
        "Wait For Low",
        "Set Pullup",
        "Set Pulldown"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.title)
                Text("Action Queue")
                    .font(.title)
                    .bold()
            }
            
            if let message = statusMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            statusMessage = nil
                        }
                    }
            }
            
            Group {
                HStack {
                    Picker("Action", selection: $selectedAction) {
                        ForEach(actions, id: \.self) { action in
                            Text(action).tag(action)
                        }
                    }
                    .frame(width: 120)
                    
                    if selectedAction == "Delay" {
                        TextField("Milliseconds", text: $delayValue)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    } else {
                        TextField("GPIO Pin", text: $selectedPin)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    Button(action: {
                        if connectionManager.isConnected {
                            let value = selectedAction == "Delay" ? delayValue : selectedPin
                            connectionManager.addAction(action: selectedAction, value: value) { success in
                                DispatchQueue.main.async {
                                    if success {
                                        queue.append((selectedAction, value))
                                        statusMessage = "Action added"
                                    } else {
                                        statusMessage = "Failed to add action"
                                    }
                                }
                            }
                        } else {
                            statusMessage = "Not connected to server"
                        }
                    }) {
                        Label("Add", systemImage: "plus.circle.fill")
                            .padding(8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!connectionManager.isConnected)
                }
                
                Toggle(isOn: $loop) {
                    Label("Loop Queue", systemImage: "repeat")
                }
                .disabled(!connectionManager.isConnected)
                
                HStack(spacing: 20) {
                    Button(action: {
                        connectionManager.startActions(loop: loop) { success in
                            DispatchQueue.main.async {
                                statusMessage = success ? "Queue started" : "Failed to start queue"
                            }
                        }
                    }) {
                        Label("Start", systemImage: "play.fill")
                            .frame(minWidth: 100)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!connectionManager.isConnected || queue.isEmpty)
                    
                    Button(action: {
                        connectionManager.stopActions { success in
                            DispatchQueue.main.async {
                                statusMessage = success ? "Queue stopped" : "Failed to stop queue"
                            }
                        }
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(minWidth: 100)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!connectionManager.isConnected)
                }
            }
            
            Text("Actions")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(queue.indices, id: \.self) { index in
                        let item = queue[index]
                        HStack {
                            if item.0 == "Set High" {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundColor(.green)
                            } else if item.0 == "Set Low" {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.red)
                            } else if item.0 == "Delay" {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                            } else if item.0.contains("Wait") {
                                Image(systemName: "hourglass")
                                    .foregroundColor(.orange)
                            } else if item.0.contains("Pull") {
                                Image(systemName: "arrow.up.and.down")
                                    .foregroundColor(.purple)
                            }
                            
                            Text("[\(index)] \(item.0) \(item.0 == "Delay" ? "\(item.1)ms" : "GPIO \(item.1)")")
                                .font(.system(size: 14, design: .monospaced))
                            
                            Spacer()
                            
                            Button(action: {
                                connectionManager.deleteAction(at: index) { success in
                                    DispatchQueue.main.async {
                                        if success {
                                            queue.remove(at: index)
                                            statusMessage = "Action deleted"
                                        } else {
                                            statusMessage = "Failed to delete action"
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(!connectionManager.isConnected)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            .frame(minHeight: 200)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Action Queue")
    }
}
