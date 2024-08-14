import UIKit
import ARKit
import simd
import Combine

class ViewController: UIViewController, ARSessionDelegate, ARKitManagerDelegate, ARSCNViewDelegate, WebSocketManagerDelegate {
 
  
    
    @IBOutlet weak var status: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var connectedStatus: UIView!
    @IBOutlet var freezeButton: UIButton!  // Connect this IBOutlet to your button in the storyboard
    
    @IBOutlet weak var cover: UIView!
    var arKitManager = ARKitManager()
    var webSocketManager = WebSocketManager()
    
    var ipAddress: String?
    var port: String?
    
    @IBOutlet weak var toggle: UIButton!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!

    var position:  SIMD3<Float>!
    var rotation:  simd_float3x3!

    
    private var cancellables = Set<AnyCancellable>()
    @IBOutlet weak var position3DView: Position3DView! // Add this outlet
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        status.text = "Sending poses to \(ipAddress!):\(port!) at "
        
        exitButton.layer.cornerRadius = exitButton.frame.height/2
        resetButton.layer.cornerRadius = resetButton.frame.height/2
        connectedStatus.layer.cornerRadius = connectedStatus.frame.height/2
        freezeButton.layer.cornerRadius = freezeButton.frame.height/2
        toggle.layer.cornerRadius = toggle.frame.height/2
        button.layer.cornerRadius = button.frame.height/2
        position3DView.layer.cornerRadius = position3DView.frame.height/40
        
        sceneView.layer.cornerRadius = sceneView.frame.height/40
        
        cover.layer.cornerRadius = cover.frame.height/16
        cover.layer.borderWidth = 0.2
        cover.layer.borderColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 1.0)

//        position3DView.layer.cornerRadius = position3DView.frame.height/20
        position3DView.layer.borderWidth = 0.2
        position3DView.layer.borderColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 1.0)
        
   
        toggle.layer.borderWidth = 0.2
        toggle.layer.borderColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        button.layer.borderWidth = 0.2
        button.layer.borderColor = CGColor.init(red: 0, green: 0, blue: 0, alpha: 1.0)

        
        let buttonRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleButtonPress(_:)))
        buttonRecognizer.minimumPressDuration = 0
        button.addGestureRecognizer(buttonRecognizer)
        
//        if let ip = ipAddress, let port = port {
//            print("IP Address: \(ip), Port: \(port)")
////            webSocketManager.connect(ip:ip,port:port)
////            arKitManager.connect(ip: ip, port: port)
//        }
//        
        
        sceneView.delegate = self
        sceneView.session = arKitManager.arSession
        
        arKitManager.delegate = self
        arKitManager.webSocketManager.delegate = self
        
        setupLongPressGesture()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        arKitManager.session(session, didUpdate: frame)
    }
    
    @IBAction func calibrateButtonPressed(_ sender: UIButton) {
        arKitManager.calibrate()
    }
    
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        arKitManager.toggleClicked()
        if sender.backgroundColor == UIColor.black{
            sender.backgroundColor = UIColor.white
            sender.tintColor = UIColor.black
        }else{
            sender.backgroundColor = UIColor.black
            sender.tintColor = UIColor.white
        }
    }
    
    @IBOutlet weak var matrix: UILabel!
    @objc func handleButtonPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
            if gestureRecognizer.state == .began {
                button.backgroundColor = UIColor.white
                button.tintColor = UIColor.black
                arKitManager.updateButton(status: true)
            } 
        else if gestureRecognizer.state == .ended {
            button.backgroundColor = UIColor.black
            button.tintColor = UIColor.white
                arKitManager.updateButton(status: false)
            }
}
    
  
    @IBOutlet weak var axisView: UIStackView!
    @IBOutlet weak var matrixView: UIView!

    @IBOutlet weak var poseView: PoseMatrixView!
    
    @IBAction func segmentControl(_ sender: UISegmentedControl) {
        
        if (sender.selectedSegmentIndex == 1){
            axisView.isHidden = true
            matrixView.isHidden = false
        } else{
            matrixView.isHidden = true
            axisView.isHidden = false
            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func exitButtonPressed(_ sender: UIButton) {
        arKitManager.disconnect()
        position3DView.sceneView.pause(self)
        sceneView.session.pause()
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - ARKitManagerDelegate Methods
    func didUpdateRotationMatrix(_ rotationMatrix: simd_float3x3) {
//        print("New rotation matrix: \(rotationMatrix)")
        position3DView.updateRotation(rotationMatrix: rotationMatrix)
        self.rotation = rotationMatrix
        
        if self.position != nil {
            let matrixValues: [[Float]] = [
                [rotation[0][0], rotation[0][1], rotation[0][2], position.x],
                [rotation[1][0], rotation[1][1], rotation[1][2], position.y],
                [rotation[2][0], rotation[2][1], rotation[2][2], position.z],
                [0, 0, 0, 1],
            ]
            poseView.updateMatrix(with: matrixValues)}
    }
    
    func didUpdatePosition(_ position: SIMD3<Float>) {
//        print("New position: \(position)")
        position3DView.updatePosition(x: position.x, y: position.y, z: position.z)
        
        self.position = position
        
        if self.rotation != nil {
            
            let matrixValues: [[Float]] = [
                [rotation[0][0], rotation[0][1], rotation[0][2], position.x],
                [rotation[1][0], rotation[1][1], rotation[1][2], position.y],
                [rotation[2][0], rotation[2][1], rotation[2][2], position.z],
                [0, 0, 0, 1],
            ]
            poseView.updateMatrix(with: matrixValues)
            
        }
        
        
        

    }
    
  
    
    func didSend(_ timeInterval: TimeInterval) {
        status.text = "Connected and sending poses to \(ipAddress!):\(port!)"
    }
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        freezeButton.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            arKitManager.freezeTransforms()
        } else if gesture.state == .ended {
            arKitManager.unfreezeTransforms()
        }
    }
}

