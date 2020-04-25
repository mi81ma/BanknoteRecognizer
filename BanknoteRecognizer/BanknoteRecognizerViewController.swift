//
//  BanknoteRecognizerViewController.swift
//  BanknoteRecognizerViewController
//
//  Created by Simon Ng on 23/11/2018.
//  Copyright © 2018 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation
import Vision



class BanknoteRecognizerViewController: UIViewController {

    @IBOutlet var cameraImageView: UIImageView!
    @IBOutlet var classifierLabel: UILabel!
    
    var captureSession = AVCaptureSession()
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            /*
             Use the Swift class `Emoji` Core ML generates from the model.
             */
            //let model = try VNCoreMLModel(for: BanknoteClassifier2().model)

//            let model = try VNCoreMLModel(for: WeAR_Azure().model)

            let model2 = try VNCoreMLModel(for: Scott2().model)
            
            let request = VNCoreMLRequest(model: model2, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)

                
            })
           
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

     
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureLiveVideo()
    }
    

    func captureLiveVideo() {
        // Create a capture device
        captureSession.sessionPreset = .photo
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            fatalError("Failed to initialize the camera device")
        }
        
        // Define the device input and output
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            fatalError("Failed to retrieve the device input for camera")
        }
        
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        captureSession.addInput(deviceInput)
        captureSession.addOutput(deviceOutput)
        
        // Add a video layer to the image view
        let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer.frame = cameraImageView.layer.frame
        cameraImageView.layer.addSublayer(cameraPreviewLayer)
        
        captureSession.startRunning()
    }

    /// Updates the UI with the results of the classification.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {

        DispatchQueue.main.async {
            
            guard let results = request.results else {
                print("Unable to classify image.")
                return
            }
            
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications = results as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                print("Nothing recognized!")
            } else {
                // Display top classifications ranked by confidence in the UI.
                guard let bestAnswer = classifications.first else { return }
                
                var predictedBanknote = bestAnswer.identifier
                
                if predictedBanknote == "Nothing" {
                    predictedBanknote = "🤷🏻‍♀️"
                }
                
                self.classifierLabel.text = predictedBanknote
                
                let topClassifications = classifications.prefix(3)
                let descriptions = topClassifications.map { classification in
                    // Formats the classification for display; e.g. "(0.37) cliff, drop, drop-off".
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                print("Classification:\n" + descriptions.joined(separator: "\n"))
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension BanknoteRecognizerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try imageRequestHandler.perform([self.classificationRequest])
        } catch {
            print(error)
        }
    }
}
