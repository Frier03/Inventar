//
//  CameraModel.swift
//  Inventar
//
//  Created by Peter Frier on 19/01/2024.
//  Copyright © 2024 Frier. All rights reserved.
//

import AVFoundation
import SwiftUI

// CameraModel
class CameraModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?

    // Barcode detection
    @Published var isScanning = true // Control scanning state
    @Published var scannedCode: String? // Store the scanned code
    
    private var boxFrame: CGRect {
            let boxSize = CGSize(width: 0.3, height: 0.3) // 30% of the view's width and height
            let boxOrigin = CGPoint(x: (1 - boxSize.width) / 2, y: (1 - boxSize.height) / 2)
            return CGRect(origin: boxOrigin, size: boxSize)
        }
    
    override init() {
        super.init()
        session.beginConfiguration()

        // Camera setup
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access back camera!")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print(error.localizedDescription)
            return
        }

        // Barcode setup
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr] // Adjust as needed

            session.commitConfiguration()
            session.startRunning()

            // Wait for the session to start running to set the rect of interest
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                metadataOutput.rectOfInterest = self.boxFrame
            }
        } else {
            print("Could not add metadata output")
        }

        session.commitConfiguration()
    }
    
    func resetScannedCode() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Change 5 to your desired number of seconds
                self.scannedCode = nil
                self.isScanning = true // Allow scanning again
            }
        }

    func check() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    DispatchQueue.main.async {
                        self.setUp()
                    }
                }
            }
        case .denied:
            alert.toggle()
        default:
            return
        }
    }

    func setUp() {
        session.startRunning()
    }

    // Delegate method for barcode scanning
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if !isScanning { return }
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                scannedCode = metadataObject.stringValue
                isScanning = false
                resetScannedCode() // Reset after a delay
            }
        }
}
