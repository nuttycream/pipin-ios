//
//  ConnectionView.swift
//  pipin
//
//  Created by bryan yao on 5/11/25.
//
import SwiftUI

struct ConnectionView: View {
    @Binding var isPresented: Bool
    @Binding var ipAddress: String
    @Binding var port: String
    var onConnect: () -> Void
    var onDisconnect: () -> Void
    var isConnected: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding()
                }.buttonStyle(PlainButtonStyle())
                Spacer()
            }

            VStack(spacing: 20) {
                Text("Enter Connection Info")
                    .font(.title2)
                    .bold()

                TextField("IP Address", text: $ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .disableAutocorrection(true)
                    // this errors out on mac target
                    //.keyboardType(.decimalPad)

                TextField("Port", text: $port)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    //.keyboardType(.numberPad)

                if isConnected {
                    Button("Disconnect") {
                        onDisconnect()
                        isPresented = false
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                } else {
                    Button("Connect") {
                        onConnect()
                        isPresented = false
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(ipAddress.isEmpty || port.isEmpty)
                }
            }
            
            Spacer()
        }.frame(minWidth: 300)
    }
}
