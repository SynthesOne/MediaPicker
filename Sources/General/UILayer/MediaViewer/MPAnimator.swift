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

fileprivate let dampingRatio: CGFloat = 0.75

protocol MPViewerBaseAnimator: UIViewControllerAnimatedTransitioning {
    var presentingDuration: TimeInterval { get set }
    var dismissingDuration: TimeInterval { get set }
}

protocol MPViewControllerAnimatable: AnyObject {
    var imageView: MPImageView { get }
    var referencedView: UIView? { get set }
    
    func presentingAnimation()
    func presentationAnimationDidFinish()
    
    func dismissingAnimation()
    func dismissalAnimationDidFinish()
    
}

final class MPAnimator: NSObject, MPViewerBaseAnimator {

    /// Preseting transition duration
    var presentingDuration: TimeInterval = 0.4

    /// Dismissing transition duration
    var dismissingDuration: TimeInterval = 0.2

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        //return correct duration
        let isPresenting = transitionContext?.isPresenting == true
        return isPresenting ? presentingDuration : dismissingDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let isPresenting = transitionContext.isPresenting

        fromViewController.beginAppearanceTransition(false, animated: transitionContext.isAnimated)
        toViewController.beginAppearanceTransition(true, animated: transitionContext.isAnimated)

        let animator: UIViewPropertyAnimator

        if isPresenting {
            guard let animatableVC = toViewController as? MPViewControllerAnimatable else {
                fatalError("view controller does not conform DTPhotoViewer")
            }

            let toView = toViewController.view!
            toView.frame = transitionContext.finalFrame(for: toViewController)

            containerView.addSubview(toView)

            if let referencedView = animatableVC.referencedView {
                animatableVC.imageView.layer.cornerRadius = referencedView.layer.cornerRadius
                animatableVC.imageView.layer.masksToBounds = referencedView.layer.masksToBounds
                animatableVC.imageView.backgroundColor = referencedView.backgroundColor
            }

            let animation = {
                animatableVC.presentingAnimation()
                animatableVC.imageView.mp.setRadius(0)
                animatableVC.imageView.backgroundColor = .clear
            }

            animator = UIViewPropertyAnimator(duration: duration, dampingRatio: dampingRatio, animations: animation)

            animator.addCompletion { _ in
                let isCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!isCancelled)

                if !isCancelled {
                    animatableVC.presentationAnimationDidFinish()
                }

                // View controller appearance status
                toViewController.endAppearanceTransition()
                fromViewController.endAppearanceTransition()
            }

            // Layer animation
            if let referencedView = animatableVC.referencedView {
                let animationGroup = CAAnimationGroup()
                animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animationGroup.duration = presentingDuration
                animationGroup.fillMode = .backwards

                // Border color
                let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
                borderColorAnimation.fromValue = referencedView.layer.borderColor
                borderColorAnimation.toValue = UIColor.clear.cgColor
                animatableVC.imageView.layer.borderColor = UIColor.clear.cgColor

                // Border width
                let borderWidthAnimation = CABasicAnimation(keyPath: "borderWidth")
                borderWidthAnimation.fromValue = referencedView.layer.borderWidth
                borderWidthAnimation.toValue = 0
                animatableVC.imageView.layer.borderWidth = referencedView.layer.borderWidth

                animationGroup.animations = [borderColorAnimation, borderWidthAnimation]
                animatableVC.imageView.layer.add(animationGroup, forKey: nil)
            }
        } else {
            guard let animatableVC = fromViewController as? MPViewControllerAnimatable else {
                fatalError("view controller does not conform DTPhotoViewer")
            }

            animatableVC.imageView.backgroundColor = .clear

            let animation = {
                animatableVC.dismissingAnimation()

                if let referencedView = animatableVC.referencedView {
                    animatableVC.imageView.layer.cornerRadius = referencedView.layer.cornerRadius
                    animatableVC.imageView.backgroundColor = referencedView.backgroundColor
                }
            }

            animator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: animation)

            animator.addCompletion { _ in
                let isCancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!isCancelled)

                if !isCancelled {
                    animatableVC.dismissalAnimationDidFinish()
                }

                // View controller appearance status
                toViewController.endAppearanceTransition()
                fromViewController.endAppearanceTransition()
            }

            // Layer animation
            if let referencedView = animatableVC.referencedView {
                let animationGroup = CAAnimationGroup()
                animationGroup.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animationGroup.duration = presentingDuration
                animationGroup.fillMode = .backwards

                // Border color
                let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
                borderColorAnimation.fromValue = UIColor.clear.cgColor
                borderColorAnimation.toValue = referencedView.layer.borderColor
                animatableVC.imageView.layer.borderColor = referencedView.layer.borderColor

                // Border width
                let borderWidthAnimation = CABasicAnimation(keyPath: "borderWidth")
                borderWidthAnimation.fromValue = 0
                borderWidthAnimation.toValue = referencedView.layer.borderWidth
                animatableVC.imageView.layer.borderWidth = referencedView.layer.borderWidth

                animationGroup.animations = [borderColorAnimation, borderWidthAnimation]
                animatableVC.imageView.layer.add(animationGroup, forKey: nil)
            }
        }

        animator.startAnimation()
    }

    public func animationEnded(_ transitionCompleted: Bool) { }
}

extension UIViewControllerContextTransitioning {
    var isPresenting: Bool {
        let toViewController = viewController(forKey: .to)
        let fromViewController = viewController(forKey: .from)
        return toViewController?.presentingViewController === fromViewController
    }
}
