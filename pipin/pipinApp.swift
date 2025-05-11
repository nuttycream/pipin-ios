//
//  pipinApp.swift
//  pipin
//
//  Created by John on 5/10/25.
//

import SwiftUI
import Combine

@main
struct pipinApp: App {
    @StateObject var connectionManager = PipinManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
        }
    }
}

// wrap the functions in a manager
// manages the connection
// from the frontend
// https://medium.com/@danciliakharmon/using-combine-to-make-api-requests-in-swiftui-5ab809968911

/*
 struct AppState {
     gpio: Arc<Mutex<Gpio>>,
     actions: Arc<Mutex<Vec<Action>>>,
     stop_it: Arc<AtomicBool>,
     log_tx: broadcast::Sender<String>,
 }

 let app = Router::new()
 .route("/", get(serve_html))
 .route("/htmx.min.js", get(serve_js))
 .route("/style.css", get(serve_css))
 .route("/setup", get(setup))
 .route("/reset", get(reset))
 .route("/terminate", get(terminate))
 .route("/get-pins", get(get_pins))
 .route("/add-action", post(add_action))
 .route("/delete-action/{index}", delete(delete_action))
 .route("/start-actions", post(start_actions))
 .route("/stop-actions", post(stop_actions))
 .route("/get-actions", get(get_actions))
 .route("/ws", any(handle_websocket))
 .with_state(appstate);
*/

class PipinManager : ObservableObject {
    @Published var ipAddress: String = ""
    @Published var port: String = "3000"
    @Published var isConnected: Bool = false
    @Published var lastError: String? = nil
    
    private var webSocketManager: WebSocketManager? = nil
    
    var baseURL: URL? {
        guard !ipAddress.isEmpty, !port.isEmpty else { return nil }
        return URL(string: "http://\(ipAddress):\(port)")
    }
    
    var wsURL: URL? {
        guard !ipAddress.isEmpty, !port.isEmpty else { return nil }
        return URL(string: "ws://\(ipAddress):\(port)/ws")
    }
    
    func connect() {
        guard let _ = baseURL else {
            lastError = "invalid ip address or port"
            return
        }
    }
    
    func connectWebSocket() {
        guard let wsURL = wsURL else { return }
        webSocketManager = WebSocketManager(url: wsURL)
        webSocketManager?.connect()
    }
    
    func disconnect() {
        webSocketManager?.disconnect()
        webSocketManager = nil
        isConnected = false
    }
    
    // considering our web server
    // renders the gpio pins
    // however for this app
    // we likely won't use get-gpio route
    
    func setupGpio(completion: @escaping (Bool) -> Void) {
        performRequest("setup", completion: completion)
    }
    
    func resetGpio(completion: @escaping (Bool) -> Void) {
        performRequest("reset", completion: completion)
    }
    
    func terminateGpio(completion: @escaping (Bool) -> Void) {
        performRequest("terminate", completion: completion)
    }
    
    // uses websocket
    func togglePin(_ pin: Int, completion: @escaping (Bool) -> Void) {
        guard let wsManager = webSocketManager, wsManager.isConnected else {
            completion(false)
            return
        }
        
        let message = ["pin": String(pin)]
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            wsManager.sendMessage(jsonString)
            completion(true)
        } else {
            completion(false)
        }
    }
    
    // for the queue list
    // don't want to store
    // actions locally
    // I do think its best
    // we can just fetch the actions from the server

    func addAction(action: String, pin: String, completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent("add-action")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let actionType = action == "Set High" ? "high" : "low"
        let body: [String: Any] = [
            "type": actionType,
            "pin": Int(pin) ?? 0
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error adding action: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response or status code")
                completion(false)
                return
            }
            
            completion(true)
        }.resume()
    }
    
    func startActions(completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent("start-actions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error starting actions: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response or status code")
                completion(false)
                return
            }
            
            completion(true)
        }.resume()
    }
    
    func stopActions(completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent("stop-actions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error stopping actions: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response or status code")
                completion(false)
                return
            }
            
            completion(true)
        }.resume()
    }
    
    func deleteAction(at index: Int, completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent("delete-action/\(index)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting action: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
                print("Invalid response or status code")
                completion(false)
                return
            }
            
            completion(true)
        }.resume()
    }
    
    private func performRequest(_ endpoint: String, completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent(endpoint)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error performing request to \(endpoint): \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response or status code")
                completion(false)
                return
            }
            
            completion(true)
        }.resume()
    }
}

// https://peerdh.com/blogs/programming-insights/implementing-websocket-connections-in-swiftui-for-real-time-data-synchronization
class WebSocketManager: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var logs: [String] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func connect() {
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
                
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        // since my web server responds with html
                        // im using htmx on the frontend
                        // pipin 0.3 and onward will work with json payload responses
                        if text.contains("log-container") {
                            // log message from HTML
                            if let range = text.range(of: #"<div id="log-container" hx-swap-oob="afterbegin">(.*?)</div>"#,
                                                      options: .regularExpression) {
                                let logMessage = String(text[range])
                                    .replacingOccurrences(of: #"<div id="log-container" hx-swap-oob="afterbegin">"#, with: "")
                                    .replacingOccurrences(of: "</div>", with: "")
                                
                                self?.logs.insert(logMessage, at: 0)
                                
                                // Limit number of logs to avoid memory issues
                                if let count = self?.logs.count, count > 100 {
                                    self?.logs = Array(self!.logs.prefix(100))
                                }
                            }
                        }
                    }
                default:
                    break
                }
                
                // continue listening for msgs
                self?.receiveMessage()
            }
        }
    }
    
    func sendMessage(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("error sending message: \(error)")
            }
        }
    }
}
