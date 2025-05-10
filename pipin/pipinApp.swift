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
