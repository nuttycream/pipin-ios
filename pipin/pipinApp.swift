//
//  pipinApp.swift
//  pipin
//
//  Created by John on 5/10/25.
//

import SwiftUI

@main
struct pipinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func setup() {
    guard let url = URL(string:"http://localhost:3000/setup") else {
        fatalError( "Could not create URL" )
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response")
            return
        }
        if httpResponse.statusCode != 200 {
            print("error")
            return
        }
    }
    
    dataTask.resume()
}

func terminate() {
    guard let url = URL(string:"http://localhost:3000/terminate") else {
        fatalError( "Could not create URL" )
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response")
            return
        }
        if httpResponse.statusCode != 200 {
            print("error")
            return
        }
    }
    
    dataTask.resume()
}

func reset() {
    guard let url = URL(string:"http://localhost:3000/reset") else {
        fatalError( "Could not create URL" )
    }
    
    let urlRequest = URLRequest(url: url)
    
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response")
            return
        }
        if httpResponse.statusCode != 200 {
            print("error")
            return
        }
    }
    
    dataTask.resume()
}

// https://peerdh.com/blogs/programming-insights/implementing-websocket-connections-in-swiftui-for-real-time-data-synchronization
class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var message: String = ""
    
    func connect() {
        let url = URL(string: "wss://localhost:3000/ws")
        webSocketTask = URLSession.shared.webSocketTask(with: url!)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("error receiving message; \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.message = text
                    }
                default:
                    break
                }
            }
            // keep lisetning for new msgs
            self?.receiveMessage()
        }
    }
    
    func sendMessage(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("error sending message; \(error)")
            }
        }
    }
}
