//
//  WeScanController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 23/11/23.
//

import UIKit
import WeScan
import PhotosUI

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
    
    @IBAction func imagePickerTapped(_ sender: UIButton) {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true)
        }
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


extension WeScanController: PHPickerViewControllerDelegate {
    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProviders = results.map(\.itemProvider)
        for item in itemProviders {
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self else { return }
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            let imageController = ImageScannerController(image: image, delegate: self)
                            self.present(imageController, animated: true)
                        }
                    }
                }
            }
        }
    }
}

extension WeScanController: ImageScannerControllerDelegate {
    func imageScannerController(_ scanner: WeScan.ImageScannerController, didFinishScanningWithResults results: WeScan.ImageScannerResults) {
        
    }
    
    func imageScannerControllerDidCancel(_ scanner: WeScan.ImageScannerController) {
        
    }
    
    func imageScannerController(_ scanner: WeScan.ImageScannerController, didFailWithError error: Error) {
        
    }
    
}
