//
//  ConfigViewController.swift
//
//  Created by Валентин Панчишен on 25.04.2024.
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
    
import Foundation
import UIKit
import MediaPicker
import SnapKit
import Combine

final class ConfigViewController: UIViewController {
    private let scrollView: UIScrollView = {
       let view = UIScrollView()
        return view
    }()
    
    private let vStack: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 16
        return view
    }()
    
    private let doneButton = {
        var bConfig = UIButton.Configuration.filled()
        bConfig.title = "done"
        bConfig.baseForegroundColor = .white
        bConfig.cornerStyle = .large
        bConfig.contentInsets = .init(top: 7, leading: 14, bottom: 7, trailing: 14)
        let view = UIButton(configuration: bConfig)
        return view
    }()
    
    private var switches: [UISwitch] = []
    private var buttons: [UIButton] = []
    private var cancellable: AnyCancellable?
    private var uiConfig: MPUIConfiguration
    
    init(uiConfig: MPUIConfiguration) {
        self.uiConfig = uiConfig
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var handleChangeUIConfig: ((MPUIConfiguration?) -> ())? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.configuration?.background.backgroundColor = uiConfig.navigationAppearance.tintColor
        view.backgroundColor = uiConfig.primaryBackgroundColor
        view.addSubview(scrollView)
        view.addSubview(doneButton)
        scrollView.addSubview(vStack)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        vStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
            $0.width.equalToSuperview().offset(-32)
        }
        doneButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        listConfig()
        
        doneButton.addAction(.init(handler: { [weak self] (_) in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
    }
    
    private func listConfig() {
        createBackgroundColorPicker()
        createTintColorPicker()
        createCheckboxColorPicker()
        createShowIndexInCheckbox()
        vStack.addArrangedSubview(UIView())
    }
    
    private func createBackgroundColorPicker() {
        let label = getLabel("Primary background color: ")
        let button = getButton("Picker", withBGColor: uiConfig.navigationAppearance.tintColor)
        buttons.append(button)
        button.addAction(.init(handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            let picker = UIColorPickerViewController()
            picker.selectedColor = strongSelf.uiConfig.primaryBackgroundColor
            strongSelf.cancellable = picker.publisher(for: \.selectedColor)
                .sink { color in
                    self?.uiConfig.primaryBackgroundColor = color
                    self?.handleChangeUIConfig?(self?.uiConfig)
                    self?.view.backgroundColor = color
                }
            strongSelf.present(picker, animated: true)
        }), for: .touchUpInside)
        
        let hStack = getHStack()
        
        hStack.addArrangedSubview(label)
        hStack.addArrangedSubview(button)
        vStack.addArrangedSubview(hStack)
    }
    
    private func createTintColorPicker() {
        let label = getLabel("Primary tint color: ")
        let button = getButton("Picker", withBGColor: uiConfig.navigationAppearance.tintColor)
        button.addAction(.init(handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            let picker = UIColorPickerViewController()
            picker.selectedColor = strongSelf.uiConfig.navigationAppearance.tintColor
            strongSelf.cancellable = picker.publisher(for: \.selectedColor)
                .sink { color in
                    self?.uiConfig.navigationAppearance.tintColor = color
                    self?.switches.forEach {
                        $0.onTintColor = color
                    }
                    self?.buttons.forEach {
                        $0.configuration?.background.backgroundColor = color
                    }
                    button.configuration?.background.backgroundColor = color
                    self?.doneButton.configuration?.background.backgroundColor = color
                    self?.handleChangeUIConfig?(self?.uiConfig)
                }
            strongSelf.present(picker, animated: true)
        }), for: .touchUpInside)
        
        let hStack = getHStack()
        
        hStack.addArrangedSubview(label)
        hStack.addArrangedSubview(button)
        vStack.addArrangedSubview(hStack)
    }
    
    private func createCheckboxColorPicker() {
        let label = getLabel("Checkbox color: ")
        let button = getButton("Picker", withBGColor: uiConfig.selectionButtonColorStyle.activeColor)
        button.addAction(.init(handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            let picker = UIColorPickerViewController()
            picker.selectedColor = strongSelf.uiConfig.selectionButtonColorStyle.activeColor
            strongSelf.cancellable = picker.publisher(for: \.selectedColor)
                .sink { color in
                    button.configuration?.background.backgroundColor = color
                    self?.uiConfig.selectionButtonColorStyle.activeColor = color
                    self?.handleChangeUIConfig?(self?.uiConfig)
                }
            strongSelf.present(picker, animated: true)
        }), for: .touchUpInside)
        
        let hStack = getHStack()
        
        hStack.addArrangedSubview(label)
        hStack.addArrangedSubview(button)
        vStack.addArrangedSubview(hStack)
    }
    
    private func createShowIndexInCheckbox() {
        let label = getLabel("Show counter in checkbox: ")
        let switchV = getSwitch(uiConfig.showCounterOnSelectionButton)
        switches.append(switchV)
        switchV.addAction(.init(handler: { [weak self] (_) in
            self?.uiConfig.showCounterOnSelectionButton = switchV.isOn
            self?.handleChangeUIConfig?(self?.uiConfig)
        }), for: .touchUpInside)
        let hStack = getHStack()
        
        hStack.addArrangedSubview(label)
        hStack.addArrangedSubview(switchV)
        vStack.addArrangedSubview(hStack)
    }
}

// MARK: - Builders func
extension ConfigViewController {
    private func getLabel(_ text: String) -> UILabel {
        let view = UILabel()
        view.text = text
        view.textColor = .label
        view.font = .systemFont(ofSize: 16, weight: .regular)
        return view
    }
    
    private func getButton(_ text: String, withBGColor color: UIColor) -> UIButton {
        var bConfig = UIButton.Configuration.filled()
        bConfig.background.backgroundColor = color
        bConfig.title = text
        bConfig.baseForegroundColor = .white
        bConfig.cornerStyle = .large
        bConfig.contentInsets = .init(top: 7, leading: 14, bottom: 7, trailing: 14)
        let view = UIButton(configuration: bConfig)
        return view
    }
    
    private func getSwitch(_ isOn: Bool) -> UISwitch {
        let view = UISwitch()
        view.isOn = isOn
        view.onTintColor = uiConfig.navigationAppearance.tintColor
        view.thumbTintColor = .white
        return view
    }
    
    private func getHStack() -> UIStackView {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillProportionally
        view.alignment = .center
        view.spacing = 8
        return view
    }
}
