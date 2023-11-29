//
//  AVScannerController.swift
//  AutoCaptureScanner
//
//  Created by Syed Razack Imran Thajudeen on 28/11/23.
//

import UIKit
import AVFoundation
import Vision

class AVScannerController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var previewView: UIView!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var captureSession = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print(error)
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = previewView.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let request = VNDetectRectanglesRequest { (request, error) in
                guard error == nil else {
                    print("Error detecting rectangles: \(error!.localizedDescription)")
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else { return }
                
                if let largestRectangle = observations.max(by: { self.calculateArea(of: $0.boundingBox) < self.calculateArea(of: $1.boundingBox) }) {
                    guard let deskewedRectangle = self.deskewRectangle(largestRectangle, in: pixelBuffer) else { return }
                    
                    DispatchQueue.main.async {
                        self.highlightRectangle(deskewedRectangle)
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform request: \(error.localizedDescription)")
            }
        }
        
        func calculateArea(of rect: CGRect) -> CGFloat {
            return rect.width * rect.height
        }
        
        func deskewRectangle(_ rectangle: VNRectangleObservation, in pixelBuffer: CVPixelBuffer) -> VNRectangleObservation? {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            
            // Convert rectangle corners from normalized coordinates to image coordinates
            let topLeft = CGPoint(x: rectangle.topLeft.x * CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                                  y: rectangle.topLeft.y * CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
            let topRight = CGPoint(x: rectangle.topRight.x * CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                                   y: rectangle.topRight.y * CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
            let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                                     y: rectangle.bottomLeft.y * CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
            let bottomRight = CGPoint(x: rectangle.bottomRight.x * CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                                      y: rectangle.bottomRight.y * CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
            
            // Perspective correction using CIFilter
            let transform = CIFilter(name: "CIPerspectiveCorrection")!
            transform.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
            transform.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
            transform.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
            transform.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
            transform.setValue(ciImage, forKey: kCIInputImageKey)
            
            guard let outputCIImage = transform.outputImage else { return nil }
            
            // Convert the transformed CIImage back to normalized rectangle coordinates
            let correctedRect = outputCIImage.extent
            let normalizedTopLeft = CGPoint(x: correctedRect.minX / outputCIImage.extent.width,
                                            y: correctedRect.minY / outputCIImage.extent.height)
            let normalizedTopRight = CGPoint(x: correctedRect.maxX / outputCIImage.extent.width,
                                             y: correctedRect.minY / outputCIImage.extent.height)
            let normalizedBottomLeft = CGPoint(x: correctedRect.minX / outputCIImage.extent.width,
                                               y: correctedRect.maxY / outputCIImage.extent.height)
            let normalizedBottomRight = CGPoint(x: correctedRect.maxX / outputCIImage.extent.width,
                                                y: correctedRect.maxY / outputCIImage.extent.height)
            
            // Create a new rectangle observation with corrected coordinates
            let correctedRectangle = VNRectangleObservation(requestRevision: <#Int#>, topLeft: normalizedTopLeft,
                                                            bottomLeft: normalizedTopRight,
                                                            bottomRight: normalizedBottomLeft,
                                                            topRight: normalizedBottomRight)
            return correctedRectangle
        }
        
        func highlightRectangle(_ rectangle: VNRectangleObservation) {
            let points = [
                rectangle.topLeft,
                rectangle.topRight,
                rectangle.bottomRight,
                rectangle.bottomLeft
            ]
            
            let convertedPoints = points.map { point in
                return videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: point)
            }
            
            let path = UIBezierPath()
            path.move(to: convertedPoints[0])
            
            for i in 1..<convertedPoints.count {
                path.addLine(to: convertedPoints[i])
            }
            
            path.close()
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.strokeColor = UIColor.red.cgColor
            shapeLayer.lineWidth = 2.0
            shapeLayer.fillColor = UIColor.clear.cgColor
            
            previewView.layer.sublayers?.removeAll { $0 is CAShapeLayer }
            previewView.layer.addSublayer(shapeLayer)
        }
}
