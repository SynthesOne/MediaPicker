//
//  ViewController.swift
//  MediaPickerExpample
//
//  Created by Валентин Панчишен on 05.04.2024.
//

import UIKit
import MediaPicker

class ViewController: UIViewController {
    
    let button: UIButton = {
        let view = UIButton(frame: CGRect(origin: .zero, size: .init(width: 120, height: 44)))
        view.setTitle("gallery", for: .normal)
        view.setTitleColor(.label, for: .normal)
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        view.addSubview(button)
        button.addTarget(self, action: #selector(openG), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        button.center = view.center
    }

    @objc func openG() {
        MPPresenter.showMediaPicker(sender: self)
    }
}

