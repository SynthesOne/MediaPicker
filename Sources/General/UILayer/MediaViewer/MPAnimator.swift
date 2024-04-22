//
//  MPAnimator.swift
//
//  Created by Валентин Панчишен on 16.04.2024.
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

private let kInitialSpringVelocity: CGFloat = 2.0
private let kDampingRatio: CGFloat = 0.75

public protocol MPViewerBaseAnimator: UIViewControllerAnimatedTransitioning {
    var presentingDuration: TimeInterval { get set }
    var dismissingDuration: TimeInterval { get set }
    var usesSpringAnimation: Bool { get set }
}

public final class MPAnimator: NSObject, MPViewerBaseAnimator {

    /// Preseting transition duration
    /// Default value is 0.15
    ///
    public var presentingDuration: TimeInterval = 0.4

    /// Dismissing transition duration
    /// Default value is 0.2
    ///
    public var dismissingDuration: TimeInterval = 0.2

    /// Indicates if using spring animation
    /// Default value is true
    ///
    public var usesSpringAnimation = false

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        //return correct duration
        let isPresenting = transitionContext?.isPresenting == true
        return isPresenting ? presentingDuration : dismissingDuration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let isPresenting = transitionContext.isPresenting

        fromViewController.beginAppearanceTransition(false, animated: transitionContext.isAnimated)
        toViewController.beginAppearanceTransition(true, animated: transitionContext.isAnimated)

        let animator: UIViewPropertyAnimator

        if isPresenting {
            guard let photoViewerController = toViewController.mp.as(MediaViewerViewController.self) else {
                fatalError("view controller does not conform DTPhotoViewer")
            }

            let toView = toViewController.view!
            toView.frame = transitionContext.finalFrame(for: toViewController)

            containerView.addSubview(toView)

            if let referencedView = photoViewerController.referencedView {
                photoViewerController.imageView.layer.cornerRadius = referencedView.layer.cornerRadius
                photoViewerController.imageView.layer.masksToBounds = referencedView.layer.masksToBounds
                photoViewerController.imageView.backgroundColor = referencedView.backgroundColor
            }

            let animation = {
                photoViewerController.presentingAnimation()
                photoViewerController.imageView.layer.cornerRadius = 0
                photoViewerController.imageView.backgroundColor = .clear
            }

//            if usesSpringAnimation {
//            UIViewP
                animator = UIViewPropertyAnimator(duration: duration, dampingRatio: kDampingRatio, animations: animation)
//            } else {
//                animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: animation)
//            }

            animator.addCompletion { _ in
                let isCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!isCancelled)

                if !isCancelled {
                    photoViewerController.presentationAnimationDidFinish()
                }

                // View controller appearance status
                toViewController.endAppearanceTransition()
                fromViewController.endAppearanceTransition()
            }

            // Layer animation
            if let referencedView = photoViewerController.referencedView {
                let animationGroup = CAAnimationGroup()
                animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animationGroup.duration = presentingDuration
                animationGroup.fillMode = .backwards

                // Border color
                let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
                borderColorAnimation.fromValue = referencedView.layer.borderColor
                borderColorAnimation.toValue = UIColor.clear.cgColor
                photoViewerController.imageView.layer.borderColor = UIColor.clear.cgColor

                // Border width
                let borderWidthAnimation = CABasicAnimation(keyPath: "borderWidth")
                borderWidthAnimation.fromValue = referencedView.layer.borderWidth
                borderWidthAnimation.toValue = 0
                photoViewerController.imageView.layer.borderWidth = referencedView.layer.borderWidth

                animationGroup.animations = [borderColorAnimation, borderWidthAnimation]
                photoViewerController.imageView.layer.add(animationGroup, forKey: nil)
            }
        } else {
            guard let photoViewerController = fromViewController.mp.as(MediaViewerViewController.self) else {
                fatalError("view controller does not conform DTPhotoViewer")
            }

            photoViewerController.imageView.backgroundColor = .clear

            let animation = {
                photoViewerController.dismissingAnimation()

                if let referencedView = photoViewerController.referencedView {
                    photoViewerController.imageView.layer.cornerRadius = referencedView.layer.cornerRadius
                    photoViewerController.imageView.backgroundColor = referencedView.backgroundColor
                }
            }

            if usesSpringAnimation {
                animator = UIViewPropertyAnimator(duration: duration, dampingRatio: kDampingRatio, animations: animation)
            } else {
                animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: animation)
            }

            animator.addCompletion { _ in
                let isCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!isCancelled)

                if !isCancelled {
                    photoViewerController.dismissalAnimationDidFinish()
                }

                // View controller appearance status
                toViewController.endAppearanceTransition()
                fromViewController.endAppearanceTransition()
            }

            // Layer animation
            if let referencedView = photoViewerController.referencedView {
                let animationGroup = CAAnimationGroup()
                animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animationGroup.duration = presentingDuration
                animationGroup.fillMode = .backwards

                // Border color
                let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
                borderColorAnimation.fromValue = UIColor.clear.cgColor
                borderColorAnimation.toValue = referencedView.layer.borderColor
                photoViewerController.imageView.layer.borderColor = referencedView.layer.borderColor

                // Border width
                let borderWidthAnimation = CABasicAnimation(keyPath: "borderWidth")
                borderWidthAnimation.fromValue = 0
                borderWidthAnimation.toValue = referencedView.layer.borderWidth
                photoViewerController.imageView.layer.borderWidth = referencedView.layer.borderWidth

                animationGroup.animations = [borderColorAnimation, borderWidthAnimation]
                photoViewerController.imageView.layer.add(animationGroup, forKey: nil)
            }
        }

        animator.startAnimation()
    }

    public func animationEnded(_ transitionCompleted: Bool) {

    }
}

extension UIViewControllerContextTransitioning {
    var isPresenting: Bool {
        let toViewController = viewController(forKey: .to)
        let fromViewController = viewController(forKey: .from)
        return toViewController?.presentingViewController === fromViewController
    }
}
