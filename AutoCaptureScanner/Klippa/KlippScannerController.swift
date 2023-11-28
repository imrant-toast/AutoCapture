//
//  KlippScannerController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 27/11/23.
//

import UIKit
import KlippaScanner

class KlippScannerController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
}


//MARK: KLIPPA SCANNER DELEGATE
extension KlippScannerController: KlippaScannerDelegate {
    
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
