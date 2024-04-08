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
        let view = MPCheckboxButton(frame: CGRect(origin: .zero, size: .init(width: 20, height: 20)))
        view.contentMode = .center
        view.contentVerticalAlignment = .center
        view.style = .circle
        view.checkBoxColor = .init(
            activeColor: UIColor.systemRed,
            inactiveColor: UIColor.systemBackground,
            inactiveBorderColor: UIColor.white,
            checkMarkColor: UIColor.white
        )
        view.checkboxLine = .init(checkBoxHeight: 20)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
        view.addSubview(button)
    }
    
    override func viewDidLayoutSubview() {
        super.viewDidLayoutSubview()
        button.center = view.center
    }

}

