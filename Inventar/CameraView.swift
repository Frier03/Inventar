//
//  CameraView.swift
//  Inventar
//
//  Created by Peter Frier on 19/01/2024.
//  Copyright © 2024 Frier. All rights reserved.
//

import SwiftUI
import AVFoundation


struct CameraView: View {
    @StateObject var camera = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)

            // Scanning Box with Animation
            Rectangle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 200, height: 200)
                .opacity(0.8)

            // Display scanned code
            if let scannedCode = camera.scannedCode {
                Text("Scanned Code: \(scannedCode)")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
            }
        }
        .onAppear(perform: {
            camera.check()
        })
        .alert(isPresented: $camera.alert) {
            Alert(title: Text("Camera Access"), message: Text("Camera access is denied. Please enable access in your settings."), dismissButton: .default(Text("Ok")))
        }
    }
}


// CameraPreview
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview?.frame = view.bounds
        camera.preview?.videoGravity = .resizeAspectFill

        if let previewLayer = camera.preview {
            view.layer.addSublayer(previewLayer)
        }

        return view
    }


    func updateUIView(_ uiView: UIView, context: Context) {}
}
