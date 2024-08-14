import UIKit
import SceneKit

class Position3DView: UIView {
    
    public var sceneView: SCNView!
    private var pointNode: SCNNode!
    private var arrowNode: SCNNode!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        sceneView = SCNView(frame: self.bounds)
        sceneView.scene = SCNScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        self.addSubview(sceneView)
        
        setupAxes()
        setupPointWithArrow()

        setupCamera()
    }
    
    private func setupAxes() {
        let axisLength: CGFloat = 10.0
        let axisRadius: CGFloat = 0.25
        let arrowHeight: CGFloat = 1.0
        let arrowRadius: CGFloat = 0.5
        
        // X Axis (Red)
        let xAxisGeometry = SCNCylinder(radius: axisRadius, height: axisLength)
        let xAxisMaterial = SCNMaterial()
        xAxisMaterial.diffuse.contents = UIColor.red
        xAxisGeometry.materials = [xAxisMaterial]
        let xAxisNode = SCNNode(geometry: xAxisGeometry)
        xAxisNode.position = SCNVector3(axisLength / 2, 0, 0)
        xAxisNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        
        // X Axis Arrow
        let xArrowGeometry = SCNCone(topRadius: 0.0, bottomRadius: arrowRadius, height: arrowHeight)
        let xArrowMaterial = SCNMaterial()
        xArrowMaterial.diffuse.contents = UIColor.red
        xArrowGeometry.materials = [xArrowMaterial]
        let xArrowNode = SCNNode(geometry: xArrowGeometry)
        xArrowNode.position = SCNVector3(axisLength, 0, 0)
        xArrowNode.eulerAngles = SCNVector3(0, 0, -Float.pi / 2)
        
        // Y Axis (Green)
        let yAxisGeometry = SCNCylinder(radius: axisRadius, height: axisLength)
        let yAxisMaterial = SCNMaterial()
        yAxisMaterial.diffuse.contents = UIColor.green
        yAxisGeometry.materials = [yAxisMaterial]
        let yAxisNode = SCNNode(geometry: yAxisGeometry)
        yAxisNode.position = SCNVector3(0, axisLength / 2, 0)
        
        // Y Axis Arrow
        let yArrowGeometry = SCNCone(topRadius: 0.0, bottomRadius: arrowRadius, height: arrowHeight)
        let yArrowMaterial = SCNMaterial()
        yArrowMaterial.diffuse.contents = UIColor.green
        yArrowGeometry.materials = [yArrowMaterial]
        let yArrowNode = SCNNode(geometry: yArrowGeometry)
        yArrowNode.position = SCNVector3(0, axisLength, 0)
        
        // Z Axis (Blue)
        let zAxisGeometry = SCNCylinder(radius: axisRadius, height: axisLength)
        let zAxisMaterial = SCNMaterial()
        zAxisMaterial.diffuse.contents = UIColor.blue
        zAxisGeometry.materials = [zAxisMaterial]
        let zAxisNode = SCNNode(geometry: zAxisGeometry)
        zAxisNode.position = SCNVector3(0, 0, axisLength / 2)
        zAxisNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        
        // Z Axis Arrow
        let zArrowGeometry = SCNCone(topRadius: 0.0, bottomRadius: arrowRadius, height: arrowHeight)
        let zArrowMaterial = SCNMaterial()
        zArrowMaterial.diffuse.contents = UIColor.blue
        zArrowGeometry.materials = [zArrowMaterial]
        let zArrowNode = SCNNode(geometry: zArrowGeometry)
        zArrowNode.position = SCNVector3(0, 0, axisLength)
        zArrowNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        
        sceneView.scene?.rootNode.addChildNode(xAxisNode)
        sceneView.scene?.rootNode.addChildNode(xArrowNode)
        sceneView.scene?.rootNode.addChildNode(yAxisNode)
        sceneView.scene?.rootNode.addChildNode(yArrowNode)
        sceneView.scene?.rootNode.addChildNode(zAxisNode)
        sceneView.scene?.rootNode.addChildNode(zArrowNode)
    }
    
    private func setupPointWithArrow() {
        // Create the point
        let pointGeometry = SCNSphere(radius: 0.7)
        let pointMaterial = SCNMaterial()
        pointMaterial.diffuse.contents = UIColor.orange
        pointGeometry.materials = [pointMaterial]
        pointNode = SCNNode(geometry: pointGeometry)
        pointNode.position = SCNVector3(0, 0, 0)  // Start at the origin
        
        // Create the axis for the point
        let axisGeometry = SCNCylinder(radius: 0.2, height: 5.0)
        let axisMaterial = SCNMaterial()
        axisMaterial.diffuse.contents = UIColor.orange
        axisGeometry.materials = [axisMaterial]
        let axisNode = SCNNode(geometry: axisGeometry)
        axisNode.position = SCNVector3(0, 2.5, 0)  // Adjust position to connect point with arrow
        axisNode.eulerAngles = SCNVector3(0, 0, 0)  // Align along Y-axis
        
        // Create the arrow for the point
        let arrowGeometry = SCNCone(topRadius: 0.0, bottomRadius: 1.0, height: 3)
        let arrowMaterial = SCNMaterial()
        arrowMaterial.diffuse.contents = UIColor.orange
        arrowGeometry.materials = [arrowMaterial]
        arrowNode = SCNNode(geometry: arrowGeometry)
        arrowNode.position = SCNVector3(0, 5.0, 0)  // Adjust position to be on top of the axis
        
        pointNode.addChildNode(axisNode)
        pointNode.addChildNode(arrowNode)
        sceneView.scene?.rootNode.addChildNode(pointNode)
    }
    
    private func setupCamera() {
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        cameraNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)

        // Position the camera to view the axes from the desired orientation
        cameraNode.position = SCNVector3(20, 20, 20)

        cameraNode.look(at: SCNVector3(0, 0, 0))

        // Adjust the camera's rotation to match the new coordinate system
//        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, -Float.pi / 2)
        
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
    }
    
    func updatePosition(x: Float, y: Float, z: Float) {
        // Apply a scaling factor to make the movement more noticeable
        let scalingFactor: Float = 10.0
        pointNode.position = SCNVector3(x * scalingFactor, y * scalingFactor, z * scalingFactor)
    }
    
    func updateRotation(rotationMatrix: simd_float3x3) {
        // Convert the rotation matrix to a quaternion
        let quaternion = simd_quatf(rotationMatrix)
        
        // Apply the rotation to the point node
        pointNode.orientation = SCNQuaternion(quaternion.imag.x, quaternion.imag.y, quaternion.imag.z, quaternion.real)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sceneView.frame = self.bounds
    }
}
