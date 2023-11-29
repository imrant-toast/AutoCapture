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

        scannerViewController = SBSDKDocumentScannerViewController(parentViewController: self,
                                                                   parentView: scannerContainerView,
                                                                   delegate: self)
        
        scannerViewController?.hideSnapButton = true
        scannerViewController?.ignoreBadAspectRatio = true
        scannerViewController?.isFlashLightEnabled = false
        
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
}


//MARK: SCAN BOT DOCUMENT SCANNER DELEGATE
extension ScanBotScanningController: SBSDKDocumentScannerViewControllerDelegate {
    
    func documentScannerViewController(_ controller: SBSDKDocumentScannerViewController,
                                       didSnapDocumentImage documentImage: UIImage,
                                       on originalImage: UIImage,
                                       with result: SBSDKDocumentDetectorResult, autoSnapped: Bool) {
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
            let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
            guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
            scanBotReviewController.originalImage = originalImage
            scanBotReviewController.polygon = polygon
            self.navigationController?.pushViewController(scanBotReviewController, animated: true)
        }
    }
    
    private func qualityAnalyzer(with image: UIImage, completionHandler: @escaping (_ quality: SBSDKDocumentQuality) -> Swift.Void) {
        let analyzer = SBSDKDocumentQualityAnalyzer()
        analyzer.analyze(on: image) { quality in
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
                let stroyboard = UIStoryboard(name: "ScanBotReview", bundle: nil)
                guard let scanBotReviewController = stroyboard.instantiateViewController(withIdentifier: "ScanBotReviewController") as? ScanBotReviewController else { return }
                scanBotReviewController.originalImage = image
                scanBotReviewController.polygon = polygon
                self.navigationController?.pushViewController(scanBotReviewController, animated: true)
            }
        }
    }
}
