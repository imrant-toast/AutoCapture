//
//  ViewController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 23/11/23.
//

import UIKit
import ScanbotSDK
import KlippaScanner

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func redirectToWeScan(_ sender: UIButton) {
        let stroyboard = UIStoryboard(name: "WeScan", bundle: nil)
        guard let scanController = stroyboard.instantiateViewController(withIdentifier: "WeScanController") as? WeScanController else { return }
        self.navigationController?.pushViewController(scanController, animated: true)
    }
    
    @IBAction func redirectToScanBot(_ sender: UIButton) {
        //startScanningScanBot()
        //return
        guard Scanbot.isLicenseValid() else {
            let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }
        let stroyboard = UIStoryboard(name: "ScanBotScanning", bundle: nil)
        guard let scanBotController = stroyboard.instantiateViewController(withIdentifier: "ScanBotScanningController") as? ScanBotScanningController else { return }
        self.navigationController?.pushViewController(scanBotController, animated: true)
    }
    
    
    @IBAction func redirectToklippaScanner(_ sender: UIButton) {
        let license = Constant.KlippaLicenseKey
        
       let klippaMenu = KlippaMenu(
            isCropEnabled: true, // auto selection -- > need to set true for auto detection
            isTimerEnabled: true, // auto capture timer -- > need to set true for auto detection
            allowTimer: true, // auto capture time icon -- > need to set true for auto detection
            userCanRotateImage: true, // after capture rotate
            userCanCropManually: true, // after capture crop
            userCanChangeColorSetting: true, // after capure color setting
            shouldGoToReviewScreenWhenImageLimitReached: false,
            isViewFinderEnabled: true // camera view access area
        )
        
        let durations = KlippaDurations(
            previewDuration: 2.0, // captured image preview screen
            timerDuration: 1.0, // auto capture detection time
            successPreviewDuration: 0.5) // success hud screen
        
        
        let klippaShutterButton = KlippaShutterButton(
            allowShutterButton: true, // Grey out shutter button - disabled state
            hideShutterButton: false // hide and show shutter button.
        )
                
        let klippaBuilder = KlippaScannerBuilder(builderDelegate: self,
                                                 license: license)
            .klippaMenu(klippaMenu)
            .klippaDurations(durations)
            .klippaShutterbutton(klippaShutterButton)
        
        klippaBuilder.startScanner(parent: self)
        
        
       /*switch klippaBuilder.build() {
        case .success(let controller):
            self.present(controller, animated: true)
        case .failure(let error):
            print("ERROR :\(error)")
        }*/
    }
}

//MARK: KLIPPA SCANNER DELEGATE
extension ViewController: KlippaScannerDelegate {
    
    func klippaScannerDidFinishScanningWithResult(result: KlippaScanner.KlippaScannerResult) {
        // Handle scan results here.
        print("didFinishScanningWithResult")
        print("multipleDocumentsModeEnabled \(result)")
        print("Scanned \(result.images.count) images")
    }
    
    func klippaScannerDidCancel() {
        print("Scanner canceled")
    }
    
    func klippaScannerDidFailWithError(error: Error) {
        switch error {
        case let licenseError as KlippaScannerLicenseError:
            print("Got licensing error from SDK: \(licenseError.localizedDescription)")
        default:
            print("Error :\(error.localizedDescription)")
        }
    }
}


extension ViewController {
    
    private func startScanningScanBot() {
        // Create the default configuration object.
        let configuration = SBSDKUIDocumentScannerConfiguration.default()

        // Behavior configuration:
        // e.g. enable multi page mode to scan several documents before processing the result.
        configuration.behaviorConfiguration.isMultiPageEnabled = false
        configuration.behaviorConfiguration.isFlashEnabled = false
        
        // UI configuration:
        // e.g. configure various colors.
        configuration.uiConfiguration.topBarBackgroundColor = UIColor.black
        configuration.uiConfiguration.topBarButtonsActiveColor = UIColor.black
        configuration.uiConfiguration.topBarButtonsInactiveColor = UIColor.white.withAlphaComponent(0.3)
        configuration.uiConfiguration.isFlashButtonHidden = true
        configuration.uiConfiguration.isMultiPageButtonHidden = true
        configuration.uiConfiguration.isAutoSnappingButtonHidden = false
        
        // Text configuration:
        // e.g. customize a UI element's text.
        configuration.textConfiguration.cancelButtonTitle = "Cancel"
        // Present the recognizer view controller modally on this view controller.
        SBSDKUIDocumentScannerViewController.present(on: self,
                                                     with: configuration,
                                                     andDelegate: self)
        
    }
}

extension ViewController: SBSDKUIDocumentScannerViewControllerDelegate {
    func scanningViewController(_ viewController: SBSDKUIDocumentScannerViewController,
                                didFinishWith document: SBSDKUIDocument) {
        // Process the scanned document.
    }
    
    private func qualityAnalyzer(with image: UIImage, completionHandler: @escaping (_ quality: SBSDKDocumentQuality) -> Swift.Void) {
        let analyzer = SBSDKDocumentQualityAnalyzer()
        analyzer.analyze(on: image) { quality in
            completionHandler(quality)
        }
    }
    
}


