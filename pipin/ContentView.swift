//
//  ContentView.swift
//  pipin
//
//  Created by John on 5/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionManager: PipinManager
    
    @State private var selectedAction = "Set Low"
    @State private var selectedPin = "0"
    @State private var queue: [(String, String)] = []
    @State private var loop = false
    
    @State private var showLogs = false
    
    @State private var selectedActionIndex = 0
    @State private var showDropdown = false
    
    @State private var showConnectionModal = true
    @State private var ipAddress = ""
    @State private var port = ""
    
    let actions = ["Set Low", "Set High"]
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .center, spacing: 20.0){
                
                Text("pipin")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                //.foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                //row setup, resest, Terminate button
                HStack {
                    Button(action: {
                    }) {
                        Text("Setup")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                        
                    }
                    
                    Button(action: {
                    }) {
                        Text("Reset")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                    }) {
                        Text("Terminate")
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    
                    
                    Button(action: {
                        showLogs.toggle()
                    }) {
                        Text("Logs")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showLogs) {
                        LogsView(showLogs: $showLogs)
                        //.presentationDetents([.fraction(0.75)]) // Appears from the bottom
                        //.background(Color.black.opacity(0.8))
                    }
                    
                    Button(action: {
                        showConnectionModal = true
                    }) {
                        Text("Connect")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showConnectionModal) {
                        ConnectionView(isPresented: $showConnectionModal, ipAddress: $ipAddress, port: $port)
                    }
                }
                
                //GPIO pins
                Text("GPIO Pins")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                //.foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ScrollView{
                    //grid of GPIO pins
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8)  {
                        ForEach(gpioPins, id: \.id) { pin in
                            Button(action: {
                                // TODO: Request to IP to toggle GPIO
                                print("Tapped \(pin.label)")
                            }) {
                                Text(pin.label)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .background(pin.color)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16.0)
                .frame(minHeight:300)
                
                
                //Queue
                Text("Queue")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                //.foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    
                    Picker("Action", selection: $selectedAction) {
                        Text("Set Low").tag("Set Low")
                        Text("Set High").tag("Set High")
                    }
                    
                    TextField("GPIO Pin", text: $selectedPin)
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        let selectedAction = actions[selectedActionIndex]
                        queue.append((selectedAction, selectedPin))
                    }
                    .padding(8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                
                Toggle("Loop", isOn: $loop)
                    .foregroundColor(.white)
                
                Button("Stop") {
                    // TODO: Stop logic
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                ForEach(queue.indices, id: \.self) { index in
                    let item = queue[index]
                    HStack{
                        Text("[Queue \(index)] \(item.0) GPIO \(item.1)")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Button("Delete") {
                            //add pop here later
                        }
                    }
                }
            }.buttonStyle(PlainButtonStyle())
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

