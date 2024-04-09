//
//  ViewController.swift
//  MediaPickerExpample
//
//  Created by Валентин Панчишен on 05.04.2024.
//

import UIKit
import MediaPicker

class ViewController: UIViewController {
    
    let button: MPCheckboxButton = {
        let view = MPCheckboxButton(frame: CGRect(origin: .zero, size: .init(width: 24, height: 24)))
        view.contentMode = .center
        view.contentVerticalAlignment = .center
        view.style = .circle
        view.checkBoxColor = .init(
            activeColor: UIColor.systemRed,
            inactiveColor: UIColor.systemBackground,
            inactiveBorderColor: UIColor(named: "checkboxBorderColor") ?? .white,
            checkMarkColor: UIColor.white
        )
        view.checkboxLine = .init(checkBoxHeight: 24)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        view.addSubview(button)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        button.center = view.center
    }

}

