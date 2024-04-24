//
//  UIAlertBuilder.swift
//
//  Created by Валентин Панчишен on 09.04.2024.
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

struct Action {
    let title: String
    let style: UIAlertAction.Style
    let color: UIColor
    let action: () -> Void
}

extension Action {
    static func `default`(_ title: String, color: UIColor = .systemBlue, action: @escaping () -> Void) -> [Action] {
        return [Action(title: title, style: .default, color: color, action: action)]
    }

    static func destructive(_ title: String, color: UIColor = .systemRed, action: @escaping () -> Void) -> [Action] {
        return [Action(title: title, style: .destructive, color: color, action: action)]
    }

    static func cancel(_ title: String, color: UIColor = .systemBlue, action: @escaping () -> Void = {}) -> [Action] {
        return [Action(title: title, style: .cancel, color: color, action: action)]
    }
}

func makeAlertController(title: String? = nil,
                                message: String? = nil,
                                attributedTitle: NSAttributedString? = nil,
                                style: UIAlertController.Style,
                                actions: [Action]) -> UIAlertController {
    let controller = UIAlertController(
        title: nil,
        message: nil,
        preferredStyle: style
    )
    
    let titleAttributes = [NSAttributedString.Key.font: Font.regular(16), NSAttributedString.Key.foregroundColor: UIColor.label]
    let messageAttributes = [NSAttributedString.Key.font: Font.regular(14), NSAttributedString.Key.foregroundColor: UIColor.label]
    
    if let title {
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        controller.setValue(titleString, forKey: "attributedTitle")
    }
    
    if let message {
        let messageString = NSAttributedString(string: message, attributes: messageAttributes)
        controller.setValue(messageString, forKey: "attributedMessage")
    } else if let attributedTitle {
        controller.setValue(attributedTitle, forKey: "attributedMessage")
    }
    
    for action in actions {
        let uiAction = UIAlertAction(title: action.title, style: action.style) { _ in
            action.action()
        }
        controller.addAction(uiAction)
    }
    return controller
}

@resultBuilder
struct ActionBuilder {

    typealias Component = [Action]

    static func buildBlock(_ children: Component...) -> Component {
        return children.flatMap { $0 }
    }

    static func buildIf(_ component: Component?) -> Component {
        return component ?? []
    }

    static func buildEither(first component: Component) -> Component {
        return component
    }

    static func buildEither(second component: Component) -> Component {
        return component
    }
}

func Alert(title: String? = nil,
                  message: String? = nil,
                  attributedTitle: NSAttributedString? = nil,
                  @ActionBuilder _ makeActions: () -> [Action]) -> UIAlertController {
    makeAlertController(
        title: title,
        message: message,
        attributedTitle: attributedTitle,
        style: .alert,
        actions: makeActions()
    )
}

func ActionSheet(title: String? = nil,
                        message: String? = nil,
                        attributedTitle: NSAttributedString? = nil,
                        @ActionBuilder _ makeActions: () -> [Action]) -> UIAlertController {
    makeAlertController(
        title: title,
        message: message,
        attributedTitle: attributedTitle,
        style: .actionSheet,
        actions: makeActions()
    )
}

func ForIn<S: Sequence>(_ sequence: S,
                        @ActionBuilder makeActions: (S.Element) -> [Action]) -> [Action] {
    return sequence
        .map(makeActions) // of type [[Action]]
        .flatMap { $0 }   // of type [Action]
}
