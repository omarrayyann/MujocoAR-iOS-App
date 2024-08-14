import ARKit
import CoreMotion
import simd

protocol ARKitManagerDelegate: AnyObject {
    func didUpdateRotationMatrix(_ rotationMatrix: simd_float3x3)
    func didUpdatePosition(_ position: SIMD3<Float>)
    func didSend(_ timeInterval: TimeInterval)
}

class ARKitManager: NSObject, ARSessionDelegate {
    var arSession = ARSession()
    var rotationMatrix: simd_float3x3 = matrix_identity_float3x3
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var delta_freeze: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var calibrationTransform: simd_float4x4 = matrix_identity_float4x4
    private let motionManager = CMMotionManager()
    @Published var isConnected: Bool = false
    @Published var toggle: Bool = false
    @Published var button: Bool = false
    @Published var webSocketManager = WebSocketManager()
    var ip = ""
    var port = ""
    var first = true
    weak var delegate: ARKitManagerDelegate?
    private var isFrozen = false
    private var frozenPosition: SIMD3<Float>?
    
    override init() {
        super.init()
        arSession.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        arSession.pause()
        arSession.run(configuration)
        
    }
    
    func connect(wsManager: WebSocketManager){
        self.webSocketManager = wsManager
    }
    
    func pauseSession() {
        arSession.pause()
        print("paused")
    }
    
    func disconnect(){
        pauseSession()
        self.webSocketManager.disconnect()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard !isFrozen else { return }
        
        if self.first {
            calibrate()
            first = false
        }
        var currentTransform = frame.camera.transform
        
        
        let m_rotationMatrix = simd_float4x4(
            SIMD4(0, -1, 0, 0),   // New X-axis (was -Z)
            SIMD4(0, 0, 1, 0),   // New Y-axis (was -X)
            SIMD4(-1, 0, 0, 0),   // New Z-axis (was Y)
            SIMD4(0, 0, 0, 1)    // No translation
        )

        // Apply the rotation to the current transform
        currentTransform = simd_mul(m_rotationMatrix, currentTransform)


        let calibratedTransform = simd_mul(currentTransform, calibrationTransform.inverse)
        
        let rotationMatrix = simd_float3x3(
            SIMD3(calibratedTransform.columns.0.x, calibratedTransform.columns.0.y, calibratedTransform.columns.0.z),
            SIMD3(calibratedTransform.columns.1.x, calibratedTransform.columns.1.y, calibratedTransform.columns.1.z),
            SIMD3(calibratedTransform.columns.2.x, calibratedTransform.columns.2.y, calibratedTransform.columns.2.z)
        )
        let position = SIMD3<Float>(calibratedTransform.columns.3.x, calibratedTransform.columns.3.y, calibratedTransform.columns.3.z)
        
        DispatchQueue.main.async {
            self.rotationMatrix = rotationMatrix
            self.position = position
            
            self.delegate?.didUpdateRotationMatrix(rotationMatrix)
            self.delegate?.didUpdatePosition(position - self.delta_freeze)
            
            var startTime = Date()
            self.webSocketManager.sendMessage(rotationMatrix: rotationMatrix, position: position - self.delta_freeze)
            var endTime = Date()
            var timeInterval = endTime.timeIntervalSince(startTime)
            self.delegate?.didSend(timeInterval)
            
        }
    }
    
    func calibrate() {
//        self.delta_freeze = SIMD3<Float>(0, 0, 0)
        
        if var currentTransformTemp = arSession.currentFrame {
            
            var currentTransform = currentTransformTemp.camera.transform
            let m_rotationMatrix = simd_float4x4(
                SIMD4(0, -1, 0, 0),   // New X-axis (was -Z)
                SIMD4(0, 0, 1, 0),   // New Y-axis (was -X)
                SIMD4(-1, 0, 0, 0),   // New Z-axis (was Y)
                SIMD4(0, 0, 0, 1)    // No translation
            )
            
            // Apply the rotation to the current transform
            currentTransform = simd_mul(m_rotationMatrix, currentTransform)
            
            currentTransform.columns.3.x -= self.delta_freeze.x
            currentTransform.columns.3.x -= self.delta_freeze.y
            currentTransform.columns.3.x -= self.delta_freeze.z
            
            calibrationTransform = currentTransform
            isFrozen = false
            frozenPosition = nil
        }
    }
    
    func updateButton(status: Bool) {
        button = status
        webSocketManager.button = button
    }
    
    func toggleClicked(){
        toggle.toggle()
        webSocketManager.toggle = toggle
    }
    
    func freezeTransforms() {
        if let frame = arSession.currentFrame {
            var currentTransform = frame.camera.transform
            let m_rotationMatrix = simd_float4x4(
                SIMD4(0, -1, 0, 0),   // New X-axis (was -Z)
                SIMD4(0, 0, 1, 0),   // New Y-axis (was -X)
                SIMD4(-1, 0, 0, 0),   // New Z-axis (was Y)
                SIMD4(0, 0, 0, 1)    // No translation
            )

            // Apply the rotation to the current transform
            currentTransform = simd_mul(m_rotationMatrix, currentTransform)
            let calibratedTransform = simd_mul(currentTransform, calibrationTransform.inverse)
            frozenPosition = SIMD3<Float>(calibratedTransform.columns.3.x, calibratedTransform.columns.3.y, calibratedTransform.columns.3.z)
        }
        isFrozen = true
    }
    
    func unfreezeTransforms() {
        if let frozenPosition = frozenPosition, let frame = arSession.currentFrame {
            var currentTransform = frame.camera.transform
            let m_rotationMatrix = simd_float4x4(
                SIMD4(0, -1, 0, 0),   // New X-axis (was -Z)
                SIMD4(0, 0, 1, 0),   // New Y-axis (was -X)
                SIMD4(-1, 0, 0, 0),   // New Z-axis (was Y)
                SIMD4(0, 0, 0, 1)    // No translation
            )

            // Apply the rotation to the current transform
            currentTransform = simd_mul(m_rotationMatrix, currentTransform)
            let calibratedTransform = simd_mul(currentTransform, calibrationTransform.inverse)
            let currentPosition = SIMD3<Float>(calibratedTransform.columns.3.x, calibratedTransform.columns.3.y, calibratedTransform.columns.3.z)
            let deltaPosition = currentPosition - frozenPosition
            self.delta_freeze = self.delta_freeze + deltaPosition
        }
        isFrozen = false
    }
}
