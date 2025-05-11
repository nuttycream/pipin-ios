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

                TextField("Port", text: $port)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Submit") {
                    // Handle connection logic here
                    isPresented = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            Spacer()
        }.frame(minWidth: 300) 
    }
}

#Preview {
    // Provide dummy state values for preview
    ConnectionView(
        isPresented: .constant(true),
        ipAddress: .constant("192.168.0.1"),
        port: .constant("8080")
    )
}
