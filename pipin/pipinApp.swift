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
    
    public var webSocketManager: WebSocketManager? = nil
    
    var baseURL: URL? {
        guard !ipAddress.isEmpty, !port.isEmpty else { return nil }
        return URL(string: "http://\(ipAddress):\(port)")
    }
    
    var wsURL: URL? {
        guard !ipAddress.isEmpty, !port.isEmpty else { return nil }
        return URL(string: "ws://\(ipAddress):\(port)/ws")
    }
    
    func connect() {
        guard let baseURL = baseURL else {
            lastError = "invalid ip address or port"
            return
        }
        
        // since this is unused im gonna use
        // this to test connection
        let url = baseURL.appendingPathComponent("get-pins")
        
        // attempt status
        DispatchQueue.main.async {
            self.lastError = "connecting..."
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("conn error: \(error)")
                    self.lastError = "failed to connect: \(error.localizedDescription)"
                    self.isConnected = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.lastError = "invalid server response"
                    self.isConnected = false
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    self.isConnected = true
                    self.lastError = nil
                    self.connectWebSocket()
                } else {
                    self.lastError = "returned status: \(httpResponse.statusCode)"
                    self.isConnected = false
                }
            }
        }.resume()
    }
    
    func connectWebSocket() {
        guard let wsURL = wsURL else {
            print("Invalid WebSocket URL")
            return
        }
        
        print("connecting to ws at \(wsURL)")
        webSocketManager = WebSocketManager(url: wsURL)
        webSocketManager?.onConnectionFailed = { [weak self] error in
            DispatchQueue.main.async {
                self?.lastError = "ws connection failed: \(error)"
            }
        }
        
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

    func addAction(action: String, value: String, completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        // the web server expects it in a specific format
        // https://stackoverflow.com/a/48727705
        let url = baseURL.appendingPathComponent("add-action")
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let actionType: String
        switch action {
        case "Set High":
            actionType = "set-high"
        case "Set Low":
            actionType = "set-low"
        case "Delay":
            actionType = "delay"
        case "Wait For High":
            actionType = "wait-for-high"
        case "Wait For Low":
            actionType = "wait-for-low"
        case "Set Pull-Up":
            actionType = "set-pull-up"
        case "Set Pull-Down":
            actionType = "set-pull-down"
        default: // fall back to low for now
            actionType = "set-low"
        }
        
        let formData = "action_type=\(actionType)&value=\(Int(value) ?? 0)"
        request.httpBody = formData.data(using: .utf8)
        
        
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
    
    func startActions(loop: Bool = false, completion: @escaping (Bool) -> Void) {
        guard let baseURL = baseURL else {
            completion(false)
            return
        }
        
        let url = baseURL.appendingPathComponent("start-actions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // use the loop
        let formData = "should_loop=\(loop ? "true" : "false")"
        request.httpBody = formData.data(using: .utf8)
        
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
    
    // utility func for basic endpoints
    // where i dont really care for the response
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
    
    var onConnectionFailed: ((String) -> Void)?
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func connect() {
        print("connecting to ws: \(url)")
        
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        
        webSocketTask?.resume()
        
        // hard limiut 2 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.pingWebSocket()
        }
        
        receiveMessage()
    }
    
    // util func to send out a ping to test
    // conn
    private func pingWebSocket() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("ping failed: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.onConnectionFailed?("ping failed: \(error.localizedDescription)")
                }
            } else {
                DispatchQueue.main.async {
                    self?.isConnected = true
                }
            }
        }
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
