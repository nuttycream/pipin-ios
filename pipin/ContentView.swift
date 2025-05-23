//
//  ContentView.swift
//  pipin
//
//  Created by John on 5/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionManager: PipinManager
    
    @State private var showLogs = false
    @State private var showConnectionModal = false
    @State private var isLoading = false
    @State private var statusMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20.0) {
                    HStack {
                        Text("pipin")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // temp
                    // send this to LogView
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
                    
                    if let message = connectionManager.lastError {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            //GPIO controsl
                            Button(action: {
                                isLoading = true
                                connectionManager.setupGpio { success in
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        statusMessage = success ? "Setup successful" : "Setup failed"
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 28))
                                    Text("Initialize")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !connectionManager.isConnected)
                            
                            Button(action: {
                                isLoading = true
                                connectionManager.resetGpio { success in
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        statusMessage = success ? "Reset successful" : "Reset failed"
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 28))
                                    Text("Reset")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !connectionManager.isConnected)
                            
                            Button(action: {
                                isLoading = true
                                connectionManager.terminateGpio { success in
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        statusMessage = success ? "Terminate successful" : "Terminate failed"
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 28))
                                    Text("Terminate")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !connectionManager.isConnected)
                        }
                        
                        // navigation
                        HStack(spacing: 16) {
                            NavigationLink(destination: QueueView()) {
                                VStack {
                                    Image(systemName: "list.bullet.rectangle")
                                        .font(.system(size: 28))
                                    Text("Queue")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.purple.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showLogs.toggle()
                            }) {
                                VStack {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 28))
                                    Text("Logs")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 80, height: 80)
                                .background(Color.orange.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showConnectionModal = true
                            }) {
                                VStack {
                                    Image(systemName: connectionManager.isConnected ? "wifi" : "wifi.slash")
                                        .font(.system(size: 28))
                                    Text(connectionManager.isConnected ? "Disconnect" : "Connect")
                                        .font(.system(size: 12))
                                }
                                .frame(width: 80, height: 80)
                                .background(connectionManager.isConnected ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    //GPIO pins
                    Text("GPIO Pins")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(gpioPins, id: \.id) { pin in
                                Button(action: {
                                    if connectionManager.isConnected {
                                        // extracting pin from label
                                        // need better way to do this imo
                                        // ideally the id
                                        if let pinNumber = Int(pin.label.components(separatedBy: " ").last ?? "") {
                                            connectionManager.togglePin(pinNumber) { success in
                                                if !success {
                                                    DispatchQueue.main.async {
                                                        statusMessage = "Failed to toggle pin"
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        statusMessage = "Not connected to server"
                                    }
                                }) {
                                    Text(pin.label)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(16)
                                        .frame(maxWidth: .infinity)
                                        .background(pin.color)
                                        .cornerRadius(6)
                                }
                                .disabled(!connectionManager.isConnected || pin.label.contains("Power") || pin.label.contains("Ground"))
                            }
                        }
                    }
                    .padding(.horizontal, 16.0)
                    .frame(minHeight: 300)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .sheet(isPresented: $showLogs) {
            LogsView(showLogs: $showLogs, logs: connectionManager.webSocketManager?.logs ?? [])
        }
        .sheet(isPresented: $showConnectionModal) {
            ConnectionView(
                isPresented: $showConnectionModal,
                ipAddress: $connectionManager.ipAddress,
                port: $connectionManager.port,
                onConnect: {
                    connectionManager.connect()
                },
                onDisconnect: {
                    connectionManager.disconnect()
                },
                isConnected: connectionManager.isConnected
            )
        }
        .onAppear {
            // shows connection view on open
            if !connectionManager.isConnected && connectionManager.ipAddress.isEmpty {
                showConnectionModal = true
            }
        }
    }
}

struct GPIOPin: Hashable {
    let id = UUID()
    let label: String
    let color: Color
}

let gpioPins: [GPIOPin] = [
    .init(label: "3v3 Power", color: .red),
    .init(label: "5v Power", color: .red),
    .init(label: "GPIO 2", color: .green),
    .init(label: "5v Power", color: .red),
    .init(label: "GPIO 3", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 4", color: .green),
    .init(label: "GPIO 14", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 15", color: .green),
    .init(label: "GPIO 17", color: .green),
    .init(label: "GPIO 18", color: .green),
    .init(label: "GPIO 27", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 22", color: .green),
    .init(label: "GPIO 23", color: .green),
    .init(label: "3v3 Power", color: .red),
    .init(label: "GPIO 24", color: .green),
    .init(label: "GPIO 10", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 9", color: .green),
    .init(label: "GPIO 25", color: .green),
    .init(label: "GPIO 11", color: .green),
    .init(label: "GPIO 8", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 7", color: .green),
    .init(label: "GPIO 0", color: .green),
    .init(label: "GPIO 1", color: .green),
    .init(label: "GPIO 5", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 6", color: .green),
    .init(label: "GPIO 12", color: .green),
    .init(label: "GPIO 13", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 19", color: .green),
    .init(label: "GPIO 16", color: .green),
    .init(label: "GPIO 26", color: .green),
    .init(label: "GPIO 20", color: .green),
    .init(label: "Ground", color: .black),
    .init(label: "GPIO 21", color: .green)
]

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PipinManager())
    }
}

