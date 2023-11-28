//
//  ReviewScanController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 23/11/23.
//

import UIKit
import WeScan

class ReviewScanController: UIViewController {
    
    private var cropController: EditImageViewController!
    
    public var quad: Quadrilateral?
    public var capturedImage: UIImage!
    
    @IBOutlet weak var reviewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        OperationQueue.main.addOperation {
            if let _ = self.quad, let _ = self.capturedImage {
                self.setupEditController()
            }
        }
    }
    
    private func setupEditController() {
        cropController = EditImageViewController(image: capturedImage,
                                                 quad: quad,
                                                 strokeColor: UIColor(red: (69.0 / 255.0), green: (194.0 / 255.0), blue: (177.0 / 255.0), alpha: 1.0).cgColor)
        cropController.view.frame = reviewView.bounds
        cropController.willMove(toParent: self)
        reviewView.addSubview(cropController.view)
        self.addChild(cropController)
        cropController.didMove(toParent: self)
        cropController.view.contentMode = .scaleAspectFit
        cropController.delegate = self
    }
    
    @IBAction func saveGalleryTapped(_ sender: UIButton) {
        cropController.cropImage()
    }

}


extension ReviewScanController: EditImageViewDelegate {
    
    func cropped(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
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
