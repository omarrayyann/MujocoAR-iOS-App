import UIKit
import NVActivityIndicatorView

class StartViewController: UIViewController {
    @IBOutlet weak var ipAddressTextField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var ipBack: UIView!
    @IBOutlet weak var portBack: UIView!

    @IBOutlet weak var loading: NVActivityIndicatorView!
    
    var webSocketManager: WebSocketManager?
    var arManager: ARKitManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectButton.layer.cornerRadius = connectButton.frame.height / 2
        portBack.layer.cornerRadius = portBack.frame.height / 2
        
        portBack.layer.borderWidth = 0.2
        portBack.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        ipBack.layer.borderWidth = 0.2
        ipBack.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        ipBack.layer.cornerRadius = ipBack.frame.height / 2
        ipAddressTextField.text = getString(forKey: "ip")
        portTextField.text = getString(forKey: "port")
        loading.stopAnimating()
    }
    
    @IBAction func howToUse(_ sender: Any) {
        if let url = URL(string: "https://github.com/omarrayyann/MujocoAR") {
            UIApplication.shared.open(url)
        }
    }
    
    func saveString(_ string: String, forKey key: String) {
        UserDefaults.standard.set(string, forKey: key)
    }

    func getString(forKey key: String) -> String {
        return UserDefaults.standard.string(forKey: key) ?? ""
    }
    
    @IBAction func proceedButtonPressed(_ sender: UIButton) {
        guard let ipAddress = ipAddressTextField.text, !ipAddress.isEmpty,
              let port = portTextField.text, !port.isEmpty else {
            
            // Show an alert if fields are empty
            let alert = UIAlertController(title: "Error", message: "Please enter both IP address and port.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        saveString(ipAddress, forKey: "ip")
        saveString(port, forKey: "port")
        
        // Show loading indicator and disable UI
        loading.startAnimating()
        setUIEnabled(false)
        
        checkWebSocketConnection(ipAddress: ipAddress, port: port) { [weak self] success, arManager in
            DispatchQueue.main.async {
                // Hide loading indicator and enable UI
                self?.loading.stopAnimating()
                self?.setUIEnabled(true)
                
                if success {
                    self!.arManager = arManager
                    // Perform the segue and pass the IP address and port
                    self?.performSegue(withIdentifier: "showARPage", sender: self)
                } else {
                    // Show an alert if the connection failed
                    let alert = UIAlertController(title: "Error", message: "Failed to Connect. Ensure that you're using the same Wi-Fi network as the host.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    func setUIEnabled(_ enabled: Bool) {
        ipAddressTextField.isEnabled = enabled
        portTextField.isEnabled = enabled
        connectButton.isEnabled = enabled
    }
    
    func checkWebSocketConnection(ipAddress: String, port: String, completion: @escaping (Bool, ARKitManager?) -> Void) {
        let webSocketManager = WebSocketManager()
        webSocketManager.connect(ip: ipAddress, port: port)
        let arKitManager = ARKitManager()
        
        // Wait for a short period to determine if the connection is successful
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            if webSocketManager.isConnected {
                arKitManager.connect(wsManager: webSocketManager)
                completion(true, arKitManager)
            } else {
                completion(false, nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showARPage" {
            if let destinationVC = segue.destination as? ViewController {
                destinationVC.ipAddress = ipAddressTextField.text
                destinationVC.port = portTextField.text
                destinationVC.arKitManager = self.arManager!
                destinationVC.modalPresentationStyle = .fullScreen // Ensure full screen presentation
            }
        }
    }
}
