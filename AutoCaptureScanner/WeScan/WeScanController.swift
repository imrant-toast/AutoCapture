//
//  WeScanController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 23/11/23.
//

import UIKit
import WeScan

class WeScanController: UIViewController {

    private var cameraController: CameraScannerViewController!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureModeButton: UIButton! {
        didSet {
            captureModeButton.isSelected = false
            captureModeButton.setTitle("Auto", for: .normal)
            captureModeButton.setTitle("Manual", for: .selected)
        }
    }
    @IBOutlet weak var flashButton: UIButton! {
        didSet {
            flashButton.isSelected = false
            flashButton.setTitle("flash off", for: .normal)
            flashButton.setTitle("flash on", for: .selected)
        }
    }
    @IBOutlet weak var captureButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        OperationQueue.main.addOperation {
            self.setupCameraController()
        }
        // Do any additional setup after loading the view.
    }
    
    private func setupCameraController() {
        cameraController = CameraScannerViewController()
        cameraController.view.frame = cameraView.bounds
        cameraController.willMove(toParent: self)
        cameraView.addSubview(cameraController.view)
        self.addChild(cameraController)
        cameraController.didMove(toParent: self)
        cameraController.delegate = self
        cameraController.isAutoScanEnabled = true
    }
    
    @IBAction func captureTapped(_ sender: UIButton) {
        cameraController.capture()
    }
    
    @IBAction func captureModeTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        cameraController.isAutoScanEnabled = sender.isSelected
        cameraController.toggleAutoScan()
    }
    @IBAction func flashTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        cameraController.toggleFlash()
    }
}


extension WeScanController: CameraScannerViewOutputDelegate {
    func captureImageFailWithError(error: Error) {
        print(error)
    }

    func captureImageSuccess(image: UIImage, withQuad quad: Quadrilateral?) {
        let stroyboard = UIStoryboard(name: "ReviewScan", bundle: nil)
        guard let editController = stroyboard.instantiateViewController(withIdentifier: "ReviewScanController") as? ReviewScanController else { return }
        editController.capturedImage = image
        editController.quad = quad
        self.navigationController?.pushViewController(editController, animated: true)
    }
}

