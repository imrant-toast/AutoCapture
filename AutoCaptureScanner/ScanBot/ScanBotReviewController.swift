//
//  ScanBotReviewController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 24/11/23.
//

import UIKit
import ScanbotSDK

class ScanBotReviewController: UIViewController {
    
    @IBOutlet weak var editImageContainer: UIView!
    public var originalImage: UIImage!
    public var polygon: SBSDKPolygon!
    private var editingViewController: SBSDKImageEditingViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        OperationQueue.main.addOperation {
            self.setupEditController()
        }
        // Do any additional setup after loading the view.
    }

    private func setupEditController() {
        editingViewController = SBSDKImageEditingViewController(parentViewController: self,
                                                                    containerView: editImageContainer)
        editingViewController.delegate = self
        editingViewController.image = originalImage
        editingViewController.polygon = polygon
    }

    @IBAction func saveToGallery(_ sender: UIButton) {
        editingViewController.applyChanges()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        var message = ""
        var title = ""
        if let error = error {
            title = "Error"
            message = error.localizedDescription
        } else {
            title = "Saved"
            message = "Your image has been saved to your photos."
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: "OK",
                                        style: .default,
                                        handler: { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }))
        present(alertController, animated: true)
    }
}


//MARK: SCAN BOT EDITING IMAGE CONTROLLER DELEGATE
extension ScanBotReviewController: SBSDKImageEditingViewControllerDelegate {
    
    func imageEditingViewController(_ editingViewController: SBSDKImageEditingViewController,
                                    didApplyChangesWith polygon: SBSDKPolygon,
                                    croppedImage: UIImage) {
        guard Scanbot.isLicenseValid() else {
            let alert = UIAlertController(title: "Tiral mode expired", message: "Trial mode deactivated. Check scanbot.io for info on how to purchase a license", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }
        UIImageWriteToSavedPhotosAlbum(croppedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        // save to gallery.
    }
}
