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
    private let imageView: UIImageView = {
        let view = UIImageView(image: .init(systemName: "camera.fill")?.mp.template)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.tintColor = .white
        return view
    }()
    
    private var session: AVCaptureSession?
    
    private var videoInput: AVCaptureDeviceInput?
    
    private var photoOutput: AVCapturePhotoOutput?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var isEnable = true {
        didSet {
            contentView.alpha = isEnable ? 1 : 0.3
        }
    }
    
    deinit {
        session?.stopRunning()
        session = nil
        Logger.log("deinit MPCameraCell")
    }
    
    override func reuseBlock() {
        //session?.stopRunning()
        //session = nil
    }
    
    override func setupSubviews() {
        backgroundColor = .systemGray
        contentView.addSubview(imageView)
    }
    
    override func adaptationLayout() {
        imageView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width / 3, height: contentView.bounds.width / 3)
        imageView.center = contentView.center
        
        previewLayer?.frame = contentView.layer.bounds
    }
    
    private func setupSession() {
        guard session == nil, (session?.isRunning ?? false) == false else {
            return
        }
        session?.stopRunning()
        if let input = videoInput {
            session?.removeInput(input)
        }
        if let output = photoOutput {
            session?.removeOutput(output)
        }
        session = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        guard let camera = backCamera() else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        videoInput = input
        photoOutput = AVCapturePhotoOutput()
        
        session = AVCaptureSession()
        
        if session?.canAddInput(input) == true {
            session?.addInput(input)
        }
        if session?.canAddOutput(photoOutput!) == true {
            session?.addOutput(photoOutput!)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        contentView.layer.masksToBounds = true
        previewLayer?.frame = contentView.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        contentView.layer.insertSublayer(previewLayer!, at: 0)
        
        DispatchQueue.global().async { [weak self] in
            self?.session?.startRunning()
        }
    }
    
    private func backCamera() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices
        for device in devices {
            if device.position == .back {
                return device
            }
        }
        return nil
    }
    
    func startCapture() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) || status == .denied {
            return
        }
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                if granted {
                    MPMainAsync {
                        self?.setupSession()
                    }
                }
            }
        } else {
            setupSession()
        }
    }
}

