import Foundation
import Combine
import simd
import UIKit

protocol WebSocketManagerDelegate: AnyObject {
}

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    @Published var toggle: Bool = false
    @Published var button: Bool = false
    @Published var isConnected: Bool = false
    @Published var receivedImage: UIImage?
    private var ipAddress: String?
    private var port: String?

    weak var delegate: WebSocketManagerDelegate?

    init() {
//        connect(0,0)
    }
    
    func connect(ip: String, port: String) {
        self.ipAddress = ip
        self.port = port
        guard let url = URL(string: "ws://\(ip):\(port)") else { // Replace with your server's local IP address
            print("Invalid URL")
            return
        }
        print("Connecting to \(url)")
        webSocketTask = URLSession(configuration: .default).webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
    }
    
    func disconnect() {
            guard let webSocketTask = webSocketTask else {
                print("WebSocket task is nil, nothing to disconnect")
                return
            }
            var message = "Exited App Session"
            if let data = message.data(using: .utf8) {
            webSocketTask.cancel(with: .goingAway, reason: data)
                                 }
            isConnected = false
            print("WebSocket task canceled")
            
        }
    
    func sendMessage(rotationMatrix: simd_float3x3, position: SIMD3<Float>) {
        let rotationArray = [
            [rotationMatrix.columns.0.x, rotationMatrix.columns.0.y, rotationMatrix.columns.0.z],
            [rotationMatrix.columns.1.x, rotationMatrix.columns.1.y, rotationMatrix.columns.1.z],
            [rotationMatrix.columns.2.x, rotationMatrix.columns.2.y, rotationMatrix.columns.2.z]
        ]
        let positionArray = [position.x, position.y, position.z]
        let message: [String: Any] = ["rotation": rotationArray, "position": positionArray, "toggle": toggle, "button": button]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
                webSocketTask?.send(wsMessage) { error in
                    if let error = error {
                        print("WebSocket send error: \(error)")
                        self.isConnected = false
                    } else {
//                        print("WebSocket message sent: \(jsonString)")
                        self.isConnected = true
                    }
                }
            }
        } catch {
            print("Failed to serialize message: \(error)")
            self.isConnected = false
        }
    }
    

}
