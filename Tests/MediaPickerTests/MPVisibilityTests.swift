import XCTest
import UIKit
import ObjectiveC.runtime
@testable import MediaPicker

@MainActor
final class MPVisibilityTests: XCTestCase {
    func testStaleHideCompletionDoesNotOverrideNewerShow() throws {
        let view = UIView()
        let scheduler = try VisibilityAnimationScheduler()
        defer { scheduler.restore() }

        view.mp.setIsHidden(true, duration: 0.3)
        view.mp.setIsHidden(false, duration: 0.3)
        // Model alpha is set by the real helper; deliver the cancelled pan's
        // newer show callback before the outstanding hide callback.
        try scheduler.completeNewestBeforeOldest()

        XCTAssertFalse(view.isHidden, "A late hide completion must not undo the newer show")
        XCTAssertEqual(view.alpha, 1)
    }

    func testStaleShowCompletionDoesNotOverrideNewerHide() throws {
        let view = UIView()
        view.isHidden = true
        view.alpha = 0
        let scheduler = try VisibilityAnimationScheduler()
        defer { scheduler.restore() }

        view.mp.setIsHidden(false, duration: 0.3)
        view.mp.setIsHidden(true, duration: 0.3)
        try scheduler.completeNewestBeforeOldest()

        XCTAssertTrue(view.isHidden, "A late show completion must not undo the newer hide")
        XCTAssertEqual(view.alpha, 0)
    }
}

@MainActor
private final class VisibilityAnimationScheduler {
    static var current: VisibilityAnimationScheduler?
    private let original: Method
    private let replacement: Method
    private var completions: [(Bool) -> Void] = []
    private var restored = false

    init() throws {
        original = try XCTUnwrap(class_getClassMethod(
            UIView.self, #selector(UIView.animate(withDuration:animations:completion:))
        ))
        replacement = try XCTUnwrap(class_getClassMethod(
            UIView.self, #selector(UIView.mp_visibilityTestsAnimate(withDuration:animations:completion:))
        ))
        Self.current = self
        method_exchangeImplementations(original, replacement)
    }

    func schedule(animations: () -> Void, completion: ((Bool) -> Void)?) {
        animations()
        if let completion { completions.append(completion) }
    }

    func completeNewestBeforeOldest() throws {
        XCTAssertEqual(completions.count, 2, "Both real helper completion closures must be captured")
        let newer = try XCTUnwrap(completions.last)
        let older = try XCTUnwrap(completions.first)
        newer(true)
        older(true)
    }

    func restore() {
        guard !restored else { return }
        method_exchangeImplementations(original, replacement)
        Self.current = nil
        restored = true
    }
}

private extension UIView {
    @objc class func mp_visibilityTestsAnimate(
        withDuration duration: TimeInterval,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)?
    ) {
        guard let scheduler = VisibilityAnimationScheduler.current else {
            mp_visibilityTestsAnimate(withDuration: duration, animations: animations, completion: completion)
            return
        }
        scheduler.schedule(animations: animations, completion: completion)
    }
}
