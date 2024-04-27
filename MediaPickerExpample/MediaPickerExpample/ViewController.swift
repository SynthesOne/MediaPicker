//
//  ViewController.swift
//  MediaPickerExpample
//
//  Created by Валентин Панчишен on 05.04.2024.
//

import Foundation
import UIKit
import MediaPicker

final class ViewController: UIViewController {
    
    private var mp: MPPresenter?
    
    private let gallery: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Gallery", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = MPUIConfiguration.default().navigationAppearance.tintColor
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let configuration: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Configuration", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.backgroundColor = MPUIConfiguration.default().navigationAppearance.tintColor
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MPUIConfiguration.default().primaryBackgroundColor
        view.addSubview(gallery)
        view.addSubview(configuration)
        gallery.addTarget(self, action: #selector(openG), for: .touchUpInside)
        configuration.addTarget(self, action: #selector(openC), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomInset = view.safeAreaInsets.bottom == 0 ? 8 : view.safeAreaInsets.bottom
        gallery.frame = .init(x: view.center.x - 128, y: view.frame.maxY - bottomInset - 44, width: 120, height: 44)
        configuration.frame = .init(x: view.center.x + 8, y: view.frame.maxY - bottomInset - 44, width: 120, height: 44)
    }

    @objc private func openG() {
        MPGeneralConfiguration.default()
            //.setBundleLangsDeploy(.main)
            //.setKeysLangsDeploy([
            //    "MPAttach": "MPAttach",
            //    "MPCancelButton": "MPCancelButton"
            //])
            //.maxMediaSelectCount(1)
        
        MPUIConfiguration.default()
//            .showCameraCell(false)
        
        mp = MPPresenter(sender: self)
        
        let formatter = ByteCountFormatter()
        mp?.showMediaPicker(selectedResult: { [weak self] (result) in
            guard let strongSelf = self else { return }
            debugPrint("Example selectedResult count \(result.count)")
            result.forEach({
                debugPrint("--------------------------------------------------")
                debugPrint("Example selectedResult size \(String(describing: $0.size))")
                debugPrint("Example selectedResult readableUnit \(formatter.string(fromByteCount: Int64($0.size ?? 0)))")
                debugPrint("Example selectedResult fullFileName \(String(describing: $0.fullFileName))")
                debugPrint("Example selectedResult fileName \(String(describing: $0.fileName))")
                debugPrint("Example selectedResult mediaExtension \(String(describing: $0.fileExtension))")
                debugPrint("Example selectedResult mimeType \(String(describing: $0.mimeType))")
                debugPrint("Example selectedResult type \($0.type)")
                let fileManager = FileManager.default
                var finalUrl: URL? = nil
                if var tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    tDocumentDirectory.appendPathComponent($0.fullFileName ?? "unknownVideo.mov")
                    finalUrl = tDocumentDirectory
                }
                debugPrint("Example selectedResult finalUrl \(finalUrl)")
                guard let finalUrl else {
                    return 
                }
                $0.saveAsset(toFile: finalUrl, completion: { (error) in
                    debugPrint("Example completion error \(error)")
                })
            })
            
            //Clean from memory
            strongSelf.mp = nil
        }) /*{ (controller) in
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        }*/
        
//        let testVc = TestVC()
//        testVc.modalPresentationStyle = .fullScreen
//        present(testVc, animated: true)
    }
    
    @objc private func openC() {
        let config = ConfigViewController()
        config.handleChangeBG = { [weak self] (color) in
            self?.view.backgroundColor = color
        }
        
        config.handleChangePrimaryTint = { [weak self] (color) in
            self?.gallery.backgroundColor = color
            self?.configuration.backgroundColor = color
        }
        present(config, animated: true)
    }
}

// ViewController for testing MPPresenter deletion from memory
class TestVC: UIViewController, UIPopoverPresentationControllerDelegate {
    var mp: MPPresenter?
    
    let button: UIButton = {
        let view = UIButton(frame: CGRect(origin: .zero, size: .init(width: 120, height: 44)))
        view.setTitle("Gallery", for: .normal)
        view.setTitleColor(.label, for: .normal)
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    let button2: UIButton = {
        let view = UIButton(frame: CGRect(origin: .zero, size: .init(width: 120, height: 44)))
        view.setTitle("Close", for: .normal)
        view.setTitleColor(.label, for: .normal)
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = MPUIConfiguration.default().primaryBackgroundColor
        view.addSubview(button)
        view.addSubview(button2)
        button.addTarget(self, action: #selector(openG), for: .touchUpInside)
        button2.addTarget(self, action: #selector(closeG), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        button.center = view.center
        button2.center = .init(x: view.center.x, y: view.center.y + 60)
    }

    @objc func openG() {
        MPGeneralConfiguration.default()
            //.setBundleLangsDeploy(.main)
            //.setKeysLangsDeploy([
            //    "MPAttach": "MPAttach",
            //    "MPCancelButton": "MPCancelButton"
            //])
            //.maxMediaSelectCount(1)
        
        MPUIConfiguration.default()
//            .showCameraCell(false)
        
        mp = MPPresenter(sender: self)
        
        let formatter = ByteCountFormatter()
        mp?.showMediaPicker(selectedResult: { [weak self] (result) in
            guard let strongSelf = self else { return }
            debugPrint("Example selectedResult count \(result.count)")
            result.forEach({
                debugPrint("--------------------------------------------------")
                debugPrint("Example selectedResult size \(String(describing: $0.size))")
                debugPrint("Example selectedResult readableUnit \(formatter.string(fromByteCount: Int64($0.size ?? 0)))")
                debugPrint("Example selectedResult fullFileName \(String(describing: $0.fullFileName))")
                debugPrint("Example selectedResult fileName \(String(describing: $0.fileName))")
                debugPrint("Example selectedResult mediaExtension \(String(describing: $0.fileExtension))")
                debugPrint("Example selectedResult mimeType \(String(describing: $0.mimeType))")
                debugPrint("Example selectedResult type \($0.type)")
            })
        }) /*{ (controller) in
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .crossDissolve
        }*/
    }
    
    @objc func closeG() {
        dismiss(animated: true)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}
