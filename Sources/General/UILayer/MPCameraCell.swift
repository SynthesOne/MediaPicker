//
//  MPCameraCell.swift
//
//  Created by Валентин Панчишен on 11.04.2024.
//  Copyright © 2024 Валентин Панчишен. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    
import UIKit
import AVFoundation

final class MPCameraCell: CollectionViewCell {
    private let iconCameraView: UIImageView = {
        let view = UIImageView(image: .init(systemName: "camera.fill")?.mp.template)
        view.contentMode = .scaleAspectFit
        view.tintColor = .white
        return view
    }()
    
    private let backgroundThumgnail: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    private let videoQueue = DispatchQueue(label: "com.mediapicker.videodata", qos: .userInitiated)
    
    private var session: AVCaptureSession?
    
    private var videoInput: AVCaptureDeviceInput?
    
    private var photoOutput: AVCapturePhotoOutput?
    
    private var videoOutput: AVCaptureVideoDataOutput?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var processSampleBuffer: ((CMSampleBuffer, CVImageBuffer, AVCaptureConnection) -> Void)?
    
    var isEnable = true {
        didSet {
            contentView.alpha = isEnable ? 1 : 0.3
        }
    }
    
    deinit {
        session?.stopRunning()
        session = nil
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        Logger.log("deinit MPCameraCell")
    }
    
    override func setupSubviews() {
        contentView.addSubview(backgroundThumgnail)
        contentView.addSubview(iconCameraView)
        setPlaceholderImage()
        iconCameraView.mp.setIsHidden(false)
    }
    
    override func adaptationLayout() {
        backgroundThumgnail.frame = contentView.bounds
        backgroundThumgnail.center = contentView.center
        iconCameraView.frame = .init(x: bounds.maxX - 40, y: 4, width: 32, height: 32)
        previewLayer?.frame = contentView.layer.bounds
        updateVideoOrientation()
    }
    
    private func setPlaceholderImage() {
        let imagePath = NSTemporaryDirectory() + "cameraCaptureImage.jpg"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)), let image = UIImage(data: data) {
            backgroundThumgnail.image = image
            backgroundColor = .none
        } else {
            backgroundThumgnail.image = nil
            backgroundColor = .systemGray
        }
    }
    
    private func setupSession() {
        guard session == nil, (session?.isRunning ?? false) == false else {
            return
        }
        session?.stopRunning()
        backgroundThumgnail.mp.setIsHidden(false)
        if let input = videoInput {
            session?.removeInput(input)
        }
        if let pOutput = photoOutput {
            session?.removeOutput(pOutput)
        }
        if let vOutput = videoOutput {
            session?.removeOutput(vOutput)
        }
        session = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        guard let camera = backCamera(), let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        videoInput = input
        photoOutput = AVCapturePhotoOutput()
        videoOutput = AVCaptureVideoDataOutput()
        
        session = AVCaptureSession()
        
        if session?.canAddInput(input) == true {
            session?.addInput(input)
        }
        
        if session?.canAddOutput(photoOutput!) == true {
            session?.addOutput(photoOutput!)
        }
        
        if session?.canAddOutput(videoOutput!) == true {
            session?.addOutput(videoOutput!)
            
            videoOutput?.alwaysDiscardsLateVideoFrames = false
            videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
            
            // It is necessary to wait at least 1 second, because at the start the camera is not stable and the image is dark.
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] (_) in
                self?.videoOutput?.setSampleBufferDelegate(self, queue: self?.videoQueue)
            })
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        contentView.layer.masksToBounds = true
        previewLayer?.frame = contentView.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        contentView.layer.insertSublayer(previewLayer!, at: 0)
        
        DispatchQueue.mp.background(qos: .background, background: { [weak self] in
            self?.session?.startRunning()
        }, completion: { [weak self] in
            self?.backgroundThumgnail.mp.setIsHidden(true, duration: 0.3)
        })
    }
    
    private func backCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first {
            return device
        }
        return nil
    }
    
    private func updateVideoOrientation() {
        guard let previewLayer else { return }
        guard previewLayer.connection!.isVideoOrientationSupported else {
            return
        }
        let statusBarOrientation = UIApplication.shared.mp.scene?.interfaceOrientation
        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation?.videoOrientation ?? .portrait
        previewLayer.frame = contentView.layer.bounds
        previewLayer.connection?.videoOrientation = videoOrientation
        previewLayer.removeAllAnimations()
    }
    
    func startCapture() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) || status == .denied {
            return
        }
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    MPMainAsync {
                        self.setupSession()
                    }
                }
            }
        } else {
            setupSession()
        }
    }
}

extension MPCameraCell: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        if let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            processSampleBuffer?(sampleBuffer, videoPixelBuffer, connection)
        }
    }
}
