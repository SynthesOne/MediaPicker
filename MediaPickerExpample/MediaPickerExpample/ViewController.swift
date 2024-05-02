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
    
    private var uiConfig: MPUIConfiguration = .default()
    private var generalConfig: MPGeneralConfiguration = .default()
    private var mp: MPPresenter?
    private var selectedModels: [MPResultModel] = []
    
    private let gallery: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Gallery", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let configuration: UIButton = {
        let view = UIButton(type: .system)
        view.setTitle("Configuration", for: .normal)
        view.setTitleColor(.white, for: .normal)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gallery.backgroundColor = uiConfig.navigationAppearance.tintColor
        configuration.backgroundColor = uiConfig.navigationAppearance.tintColor
        view.backgroundColor = uiConfig.primaryBackgroundColor
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
        mp = MPPresenter(sender: self, preSelectedResults: selectedModels.map { MPPhotoModel(asset: $0.asset) })
        
        let formatter = ByteCountFormatter()
        mp?.showMediaPicker(
            configuration: { [weak self] (config) in
                guard let strongSelf = self else { return MPConfigurationMaker.default }
                return config
                    .setUIConfiguration(strongSelf.uiConfig)
                    .setGeneralConfiguration(strongSelf.generalConfig)
                //---- or ----
                //return config
                //    .setShowCameraCell(false)
                //    .setPrimaryBackgroundColor(.black)
                //    .setBundleLangsDeploy(.main)
                //    .setKeysLangsDeploy([
                //        "MPAttach": "MPAttach",
                //        "MPCancelButton": "MPCancelButton"
                //    ])
                //    .setMaxMediaSelectCount(1)
            },
            selectedResult: { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.selectedModels = result
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
                debugPrint("Example selectedResult finalUrl \(String(describing: finalUrl))")
                guard let finalUrl else {
                    return 
                }
                $0.saveAsset(toFile: finalUrl, completion: { (error) in
                    debugPrint("Example completion error \(String(describing: error?.localizedDescription))")
                })
            })
            
            //Clean from memory
            strongSelf.mp = nil
        }) /*{ (controller) in
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        }*/
    }
    
    @objc private func openC() {
        let config = ConfigViewController(uiConfig: uiConfig)
        config.handleChangeUIConfig = { [weak self] (uiConfig) in
            if let uiConfig {
                self?.uiConfig = uiConfig
                self?.view.backgroundColor = uiConfig.primaryBackgroundColor
                self?.gallery.backgroundColor = uiConfig.navigationAppearance.tintColor
                self?.configuration.backgroundColor = uiConfig.navigationAppearance.tintColor
            }
        }
        present(config, animated: true)
    }
}
