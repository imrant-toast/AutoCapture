//
//  ScanBotScanningController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 24/11/23.
//

import UIKit
import ScanbotDocumentScannerSDK

class ScanBotScanningController: UIViewController {

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
            flashButton.setTitle("Flash ON", for: .normal)
            flashButton.setTitle("Flash OFF", for: .selected)
        }
    }
    private var scannerViewController: SBSDKDocumentScannerViewController?
    
    @IBOutlet weak var scannerContainerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        scannerViewController = SBSDKDocumentScannerViewController(parentViewController: self,
                                                                   parentView: scannerContainerView,
                                                                   delegate: self)
        scannerViewController?.hideSnapButton = true
        scannerViewController?.ignoreBadAspectRatio = true
        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeFlashMode(_ sender: UIButton) {
        
    }
    
    @IBAction func changeCaptureMode(_ sender: UIButton) {
        sender.isSelected.toggle()
        if let _ = scannerViewController {
            scannerViewController?.autoSnappingMode = sender.isSelected ? .disabled : .enabled
        }
    }
    
    @IBAction func captureTapped(_ sender: UIButton) {
        if let _ = scannerViewController {
            scannerViewController?.captureDocumentImage()
        }
    }
}


//MARK: SCAN BOT DOCUMENT SCANNER DELEGATE
extension ScanBotScanningController: SBSDKDocumentScannerViewControllerDelegate {
    
    func documentScannerViewController(_ controller: SBSDKDocumentScannerViewController,
                                       didSnapDocumentImage documentImage: UIImage,
                                       on originalImage: UIImage,
                                       with result: SBSDKDocumentDetectorResult, autoSnapped: Bool) {
        // moving to review controller
        if let polycon = result.polygon {
            guard Scanbot.isLicenseValid() else {
                let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
                return
            }
            let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
            guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
            scanBotReviewController.originalImage = originalImage
            scanBotReviewController.polygon = polycon
            self.navigationController?.pushViewController(scanBotReviewController, animated: true)
        }
    }
}
