//
//  ScanBotScanningController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 24/11/23.
//

// Document Scanner SPM: https://github.com/doo/scanbot-document-scanner-sdk-ios-spm.git

import UIKit
import ScanbotSDK
import PhotosUI

class ScanBotScanningController: UIViewController {

    private var multiPageData = [MulitpageScanner]()
    
    @IBOutlet weak var reviewButton: UIButton! {
        didSet {
            self.reviewButton.isHidden = true
        }
    }
    @IBOutlet weak var modeSwitch: UISwitch! {
        didSet {
            modeSwitch.setOn(true, animated: true)
        }
    }
    @IBOutlet weak var typeLabel: UILabel!
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
            flashButton.setTitle("Flash OFF", for: .normal)
            flashButton.setTitle("Flash ON", for: .selected)
        }
    }
    private var scannerViewController: SBSDKDocumentScannerViewController?
    
    @IBOutlet weak var scannerContainerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        OperationQueue.main.addOperation {
            TimingManager.sharedInstance.startTiming()
            self.startCamera()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        flashButton.isSelected = false
    }
    
    private func startCamera() {
        scannerViewController = SBSDKDocumentScannerViewController(parentViewController: self,
                                                                   parentView: scannerContainerView,
                                                                   delegate: self)
        
        // Button action customization
        
        scannerViewController?.hideSnapButton = true
        scannerViewController?.ignoreBadAspectRatio = true
        scannerViewController?.isFlashLightEnabled = false
       /* // Hint text customization
        scannerViewController?.statusTextConfiguration.textHintNothingDetected = "Onnum detect panna mudiyala" // document not appera in camera view
        scannerViewController?.statusTextConfiguration.textHintTooDark = "Onnumey theyriyala" // light not enough
        scannerViewController?.statusTextConfiguration.textHintTooSmall = "Thoorama irruku" // documen to camera view to high need to come closuer
        scannerViewController?.statusTextConfiguration.textHintOKManualScan = "Nee thaan photo pudicha" // capture by manual tap
        scannerViewController?.statusTextConfiguration.textHintOKAutoShutter = "Ennakku theyrium nee moodu" // capturing document
        scannerViewController?.statusTextConfiguration.textHintOffCenter = "Nadu center vai paper ah" // document not in center*/

        // Color customizatiom
        scannerViewController?.polygonLineWidth = 3
        scannerViewController?.polygonFillColorRejected = UIColor.red.withAlphaComponent(0.1) // during scanning border color --> scanning
        scannerViewController?.polygonLineColorRejected = UIColor.red.withAlphaComponent(0.3) // during scanning fill color --> scanning

        scannerViewController?.polygonLineColorAccepted = UIColor.green.withAlphaComponent(0.1) // proper position and stability ready to capture border color
        scannerViewController?.polygonFillColorAccepted = UIColor.green.withAlphaComponent(0.3) // proper position and stability ready to capture fill color
        
        scannerViewController?.polygonAutoSnapProgressColor = UIColor.green.withAlphaComponent(0.5) // start capturing document
        scannerViewController?.polygonAutoSnapProgressLineWidth = 3
        // scannerViewController?.playBleepSound() // while open the screen.
        // Do any additional setup after loading the view.
    }
    
    @IBAction func changeFlashMode(_ sender: UIButton) {
        sender.isSelected.toggle()
        if let _ = scannerViewController {
            scannerViewController?.isFlashLightEnabled = sender.isSelected
        }
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
    
    @IBAction func loadFromPhotos(_ sender: UIButton) {
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 1
            configuration.filter = .images
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true)
        }
    }
    
    @IBAction func modeToggeling(_ sender: UISwitch) {
        if sender.isOn {
            if multiPageData.count > 0 {
                discardChangeAlert()
                return
            }
            typeLabel.text = "Single page"
        } else if sender.isOn == false {
            typeLabel.text = "Mulitple page"
            if multiPageData.count > 0 {
                self.reviewButton.isHidden = false
                self.reviewButton.setTitle("\(multiPageData.count) photos", for: .normal)
            }
        }
    }
    
    @IBAction func reviewTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Info", message: "Multi page redirection UI not yet completed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func detectPolygon(with image: UIImage) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Create a document page by passing the image
            // You can pass the polygon of the area where the document is located within the pages image
            // You can also pass the type of the filter you want to apply on the page
            let page = SBSDKUIPage(image: image, polygon: nil, filter: SBSDKImageFilterTypeNone)
            // Detect a document on the page
            guard let result = page.detectDocument(true) else { return }
            let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
            guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
            scanBotReviewController.originalImage = image
            scanBotReviewController.polygon = result.polygon
            self.navigationController?.pushViewController(scanBotReviewController, animated: true)
        }
    }
    
    private func discardChangeAlert() {
        let alert = UIAlertController(title: "Info", message: "You're trying to switch multiple page scan to single page scan, we can't able to retain all pages", preferredStyle: .alert)
        alert.addAction(.init(title: "switch to single page", style: .destructive
                              , handler: { _ in
            self.modeSwitch.isOn = true
            self.typeLabel.text = "Single page"
            self.reviewButton.isHidden = true
            self.multiPageData.removeAll()
        }))
        alert.addAction(.init(title: "Keep multiple page scan", style: .cancel, handler: { _ in
            self.modeSwitch.isOn = false
            self.typeLabel.text = "Multiple page"
        }))
        present(alert, animated: true)
    }
}


//MARK: SCAN BOT DOCUMENT SCANNER DELEGATE
extension ScanBotScanningController: SBSDKDocumentScannerViewControllerDelegate {
    
    func documentScannerViewController(_ controller: SBSDKDocumentScannerViewController,
                                       didSnapDocumentImage documentImage: UIImage,
                                       on originalImage: UIImage,
                                       with result: SBSDKDocumentDetectorResult, autoSnapped: Bool) {
        TimingManager.sharedInstance.retreiveTiming()
        guard Scanbot.isLicenseValid() else {
            let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }
        print(autoSnapped ? "capture by auto" : "manual capture by button")
        self.qualityAnalyzer(with: documentImage) { quality in
            switch quality {
            case .noDocument:
                print("No document was found")
                let alert = UIAlertController(title: "Quality Analyzer failed", message: "No document was found", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(alert, animated: true)
                return
            case .veryPoor:
                print("The quality of the document is very poor")
            case .poor:
                print("The quality of the document is poor")
            case .reasonable:
                print("The quality of the document is reasonable")
            case .good:
                print("The quality of the document is good")
            case .excellent:
                print("The quality of the document is excellent")
            @unknown default:
                break
            }
        }
        // moving to review controller
        if let polygon = result.polygon {
            guard Scanbot.isLicenseValid() else {
                let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
                return
            }
            if modeSwitch.isOn == false {
                multiPageData.append(.init(documentImage: documentImage,
                                           originalImage: originalImage,
                                           polygon: polygon))
                self.reviewButton.isHidden = false
                self.reviewButton.setTitle("\(self.multiPageData.count) photos", for: .normal)
                return
            }
            let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
            guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
            scanBotReviewController.originalImage = originalImage
            scanBotReviewController.polygon = polygon
            self.navigationController?.pushViewController(scanBotReviewController, animated: true)
        }
    }
    
    private func qualityAnalyzer(with image: UIImage, completionHandler: @escaping (_ quality: SBSDKDocumentQuality) -> Swift.Void) {
        let analyzer = SBSDKDocumentQualityAnalyzer()
        //let quality = analyzer.analyze(on: image) // sync
        analyzer.analyze(on: image) { quality in // async
            completionHandler(quality)
        }
    }
}


extension ScanBotScanningController: PHPickerViewControllerDelegate {
    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard Scanbot.isLicenseValid() else {
            let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }
        let itemProviders = results.map(\.itemProvider)
        for item in itemProviders {
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self else { return }
                    if let image = image as? UIImage {
                        self.qualityAnalyzer(with: image) { quality in
                            if quality != .noDocument {
                                //self.detectPolygon(with: image)
                                self.rectDetector(with: image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func rectDetector(with image: UIImage) {
        let decector = SBSDKDocumentDetector()
        let result = decector.detectPhotoPolygon(on: image,
                                                                visibleImageRect: .zero,
                                                                smoothingEnabled: false)
        if result.isDetectionStatusOK, let polygon = result.polygon {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.modeSwitch.isOn == false {
                    self.multiPageData.append(.init(documentImage: image,
                                               originalImage: image,
                                               polygon: polygon))
                    self.reviewButton.isHidden = false
                    self.reviewButton.setTitle("\(self.multiPageData.count) photos", for: .normal)
                    return
                }
                let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
                guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
                scanBotReviewController.originalImage = image
                scanBotReviewController.polygon = polygon
                self.navigationController?.pushViewController(scanBotReviewController, animated: true)
            }
        }
    }
}


struct MulitpageScanner {
    let documentImage: UIImage?
    let originalImage: UIImage?
    let polygon: SBSDKPolygon?
}
