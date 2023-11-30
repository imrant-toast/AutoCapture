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
        TimingManager.sharedInstance.startTiming()
        let license = Constant.KlippaLicenseKey
        
       let klippaMenu = KlippaMenu(
            isCropEnabled: true, // auto selection -- > need to set true for auto detection
            isTimerEnabled: true, // auto capture timer -- > need to set true for auto detection
            allowTimer: true, // auto capture time icon -- > need to set true for auto detection
            userCanRotateImage: true, // after capture rotate
            userCanCropManually: true, // after capture crop
            userCanChangeColorSetting: true, // after capure color setting
            shouldGoToReviewScreenWhenImageLimitReached: true,
            isViewFinderEnabled: false // camera view access area
        )
        
        let durations = KlippaDurations(
            previewDuration: 2.0, // captured image preview screen
            timerDuration: 1.0, // auto capture detection time
            successPreviewDuration: 0.5) // success hud screen
        
        
        let klippaShutterButton = KlippaShutterButton(
            allowShutterButton: true, // Grey out shutter button - disabled state
            hideShutterButton: false // hide and show shutter button.
        )
        
        let klippaCameraModes = KlippaCameraModes(
            modes: [
                // The document mode for scanning a single-page document.
                KlippaSingleDocumentMode(
                    name: "Single Document",
                    instructions: Instructions(
                        message: "Single Document Instructions",
                        dismissHandler: {
                            print("Single document mode instructions dismissed.")
                        })
                ),
                // The document mode for scanning a document which consists of multiple pages.
                KlippaMultipleDocumentMode(
                    name: "Multiple Document",
                    instructions: Instructions(
                        message: "Multiple Document Instructions",
                        dismissHandler: {
                            print("Multiple document mode instructions dismissed.")
                        })
                ),
                // The document mode for scanning a single-page document with multiple photo captures. Suitable for scanning long receipts.
                KlippaSegmentedDocumentMode(
                    name: "Segmented Document",
                    instructions: Instructions(
                        message: "Segmented Document Instructions",
                        dismissHandler: {
                            print("Segmented document mode instructions dismissed.")
                        })
                )
            ],
            // The index to set which camera mode will be shown as default.
            startingIndex: 0)
        
        let klippaBuilder = KlippaScannerBuilder(builderDelegate: self,
                                                 license: license)
        
            .klippaMenu(klippaMenu)
            .klippaDurations(durations)
            .klippaShutterbutton(klippaShutterButton)
            .klippaCameraModes(klippaCameraModes)
        
        klippaBuilder.startScanner(parent: self)
        
        
      /* switch klippaBuilder.build() {
        case .success(let controller):
            self.present(controller, animated: true)
        case .failure(let error):
            print("ERROR :\(error)")
        } */
    }
    @IBAction func redirectToDefaultScanBot(_ sender: UIButton) {
        guard Scanbot.isLicenseValid() else {
            let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }
        self.startScanningScanBot()
    }
}

//MARK: KLIPPA SCANNER DELEGATE
extension ViewController: KlippaScannerDelegate {
    
    func klippaScannerDidFinishScanningWithResult(result: KlippaScanner.KlippaScannerResult) {
        // Handle scan results here.
        print("didFinishScanningWithResult")
        print("multipleDocumentsModeEnabled \(result)")
        print("Scanned \(result.images.count) images")
        TimingManager.sharedInstance.retreiveTiming()
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
        /*configuration.uiConfiguration.topBarBackgroundColor = UIColor.red
        configuration.uiConfiguration.topBarButtonsActiveColor = UIColor.red
        configuration.uiConfiguration.topBarButtonsInactiveColor = UIColor.white.withAlphaComponent(0.3)*/
        configuration.uiConfiguration.isFlashButtonHidden = false
        configuration.uiConfiguration.isMultiPageButtonHidden = false
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
        if document.numberOfPages() == 1 {
            let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
            guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
            scanBotReviewController.originalImage = document.page(at: 0)?.originalImage()
            scanBotReviewController.polygon = document.page(at: 0)?.polygon
            self.navigationController?.pushViewController(scanBotReviewController, animated: true)
        } else {
            let alert = UIAlertController(title: "Info", message: "Multi page redirection UI not yet completed", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }
    
    private func qualityAnalyzer(with image: UIImage, completionHandler: @escaping (_ quality: SBSDKDocumentQuality) -> Swift.Void) {
        let analyzer = SBSDKDocumentQualityAnalyzer()
        analyzer.analyze(on: image) { quality in
            completionHandler(quality)
        }
    }
    
}


final class TimingManager {
    
    static let sharedInstance = TimingManager()
    private var lastEventTime = Date()
    
    public func startTiming() {
        lastEventTime = Date()
    }
    
    public func retreiveTiming() {
        let timeInterval = Date().timeIntervalSince(lastEventTime)
        print(String(format: "timing_interval_for = %.2f seconds", timeInterval))
    }
    
}

