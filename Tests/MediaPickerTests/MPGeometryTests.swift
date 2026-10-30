import XCTest
import UIKit
import Photos
import ObjectiveC.runtime
@testable import MediaPicker

@MainActor
final class MPGeometryTests: XCTestCase {
    func testPresentationCentersImageInOffsetViewerBounds() {
        let viewer = makeViewer()
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 900, height: 1000))
        viewer.view.frame = CGRect(x: 40, y: 300, width: 400, height: 500)
        root.addSubview(viewer.view)

        viewer.presentingAnimation()

        XCTAssertEqual(viewer.imageView.center, CGPoint(x: 200, y: 250))
    }

    func testLayoutKeepsScrollContentInsideOffsetViewerBounds() throws {
        let viewer = makeViewer()
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 900, height: 1000))
        viewer.view.frame = CGRect(x: 40, y: 300, width: 400, height: 500)
        root.addSubview(viewer.view)

        viewer.viewWillLayoutSubviews()

        let scrollView = try XCTUnwrap(viewer.view.subviews.compactMap { $0 as? UIScrollView }.first)
        XCTAssertEqual(scrollView.frame, CGRect(x: 0, y: 0, width: 400, height: 500))
    }

    func testPanUsesViewerBoundsInsteadOfSuperviewCenter() {
        let viewer = makeViewer()
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 900, height: 1000))
        viewer.view.frame = CGRect(x: 40, y: 300, width: 400, height: 500)
        root.addSubview(viewer.view)
        let gesture = GeometryPanGesture()
        viewer.view.addGestureRecognizer(gesture)

        viewer._handlePanGesture(gesture)

        XCTAssertEqual(viewer.imageView.center, CGPoint(x: 200, y: 280))
    }

    func testDismissalPreservesRealScaleOfReferenceAncestor() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 1000))
        let picker = UIView(frame: CGRect(x: 30, y: 300, width: 400, height: 500))
        root.addSubview(picker)
        picker.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let thumbnail = UIView(frame: CGRect(x: 20, y: 50, width: 100, height: 80))
        picker.addSubview(thumbnail)
        let viewer = makeViewer(reference: thumbnail)
        viewer.view.frame = root.bounds
        root.addSubview(viewer.view)

        viewer.dismissingAnimation()

        XCTAssertEqual(viewer.imageView.frame, CGRect(x: 140, y: 450, width: 50, height: 40))
    }

    func testDismissalConvertsReferenceIntoOffsetViewerCoordinates() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 1000))
        let picker = UIView(frame: CGRect(x: 30, y: 300, width: 400, height: 500))
        root.addSubview(picker)
        let thumbnail = UIView(frame: CGRect(x: 20, y: 50, width: 100, height: 80))
        picker.addSubview(thumbnail)
        let viewer = makeViewer(reference: thumbnail)
        viewer.view.frame = CGRect(x: 0, y: 200, width: 400, height: 500)
        root.addSubview(viewer.view)

        viewer.dismissingAnimation()

        XCTAssertEqual(viewer.imageView.frame, CGRect(x: 50, y: 150, width: 100, height: 80))
    }

    func testMissingThumbnailFallbackUsesViewerBounds() {
        let viewer = makeViewer()
        viewer.view.frame = CGRect(x: 40, y: 300, width: 400, height: 500)

        viewer.dismissingAnimation()

        XCTAssertEqual(viewer.imageView.frame, CGRect(x: 199.5, y: 249.5, width: 1, height: 1))
    }

    func testPresentationPreparationRecalculatesSourceAfterViewerMoves() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 900, height: 1000))
        let picker = UIView(frame: CGRect(x: 40, y: 350, width: 400, height: 400))
        root.addSubview(picker)
        let thumbnail = UIView(frame: CGRect(x: 20, y: 70, width: 100, height: 80))
        picker.addSubview(thumbnail)
        let viewer = makeViewer(reference: thumbnail)
        viewer.loadViewIfNeeded()
        viewer.imageView.frame = CGRect(x: 60, y: 420, width: 100, height: 80)
        viewer.view.frame = CGRect(x: 0, y: 300, width: 400, height: 400)
        root.addSubview(viewer.view)

        viewer.presentationAnimationWillStart()

        XCTAssertEqual(viewer.imageView.frame, CGRect(x: 60, y: 120, width: 100, height: 80))
    }

    func testAnimatorRecalculatesThumbnailAfterDestinationFrameIsAssigned() async {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 900, height: 1000))
        let picker = UIViewController()
        picker.view.frame = CGRect(x: 40, y: 350, width: 400, height: 400)
        root.addSubview(picker.view)
        let thumbnail = UIView(frame: CGRect(x: 20, y: 70, width: 100, height: 80))
        picker.view.addSubview(thumbnail)
        let container = UIView(frame: root.bounds)
        root.addSubview(container)
        let viewer = GeometryAnimatableController()
        viewer.presenter = picker
        viewer.referencedView = thumbnail
        viewer.imageView.frame = CGRect(x: 60, y: 420, width: 100, height: 80)
        let started = expectation(description: "Presentation reads its local source frame")
        var initialFrame: CGRect?
        viewer.onPresentation = {
            initialFrame = viewer.imageView.frame
            started.fulfill()
        }
        let context = GeometryTransitionContext(
            from: picker, to: viewer, container: container,
            destinationFrame: CGRect(x: 0, y: 300, width: 400, height: 400)
        )
        defer { viewer.onPresentation = nil }
        let animator = MPAnimator()
        animator.presentingDuration = 0

        animator.animateTransition(using: context)
        await fulfillment(of: [started], timeout: 1)

        XCTAssertEqual(initialFrame, CGRect(x: 60, y: 120, width: 100, height: 80))
    }

    func testAlbumPopoverAnchorsToVisibleTitleBounds() throws {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [], options: nil)
        let collection = PHAssetCollection.transientAssetCollection(with: [], title: "Geometry test")
        let album = MPAlbumModel(
            title: "Geometry test", result: result, collection: collection,
            option: PHFetchOptions(), isCameraRoll: false, generalConfig: .default()
        )
        let picker = MPViewController(
            albumModel: album, selectedResults: [], uiConfig: .default(), generalConfig: .default()
        )
        picker.loadViewIfNeeded()
        let nav = try XCTUnwrap(
            Mirror(reflecting: picker).children.first { $0.label == "albumListNavView" }?.value as? MPAlbumPickerNavView
        )
        nav.sourceView.bounds = CGRect(x: 0, y: 0, width: 100, height: 22)
        var presented: UIViewController?
        try interceptPresentation(on: MPViewController.self, capture: { presented = $0 }) {
            nav.albumMenuActionSubject.send((nav, true))
        }
        let popover = try XCTUnwrap(presented?.popoverPresentationController)

        XCTAssertTrue(popover.sourceView === nav.sourceView)
        XCTAssertEqual(popover.sourceRect, CGRect(x: 0, y: 0, width: 100, height: 22))
    }

    private func makeViewer(reference: UIView? = nil) -> MediaViewerViewController {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 200))
        }
        return MediaViewerViewController(
            referencedView: reference, image: image,
            model: [MPPhotoModel(asset: GeometryAsset())], selectedModels: [], index: 0,
            uiConfig: .default(), generalConfig: .default()
        )
    }

    private func interceptPresentation(
        on controllerClass: AnyClass,
        capture: @escaping (UIViewController) -> Void,
        action: () -> Void
    ) throws {
        let selector = #selector(UIViewController.present(_:animated:completion:))
        let method = try XCTUnwrap(class_getInstanceMethod(controllerClass, selector))
        let original = method_getImplementation(method)
        let encoding = method_getTypeEncoding(method)
        let block: @convention(block) (AnyObject, UIViewController, Bool, AnyObject?) -> Void = { _, presented, _, _ in
            capture(presented)
        }
        let replacement = imp_implementationWithBlock(block)
        class_replaceMethod(controllerClass, selector, replacement, encoding)
        defer {
            class_replaceMethod(controllerClass, selector, original, encoding)
            imp_removeBlock(replacement)
        }
        action()
    }
}

private final class GeometryAsset: PHAsset {
    override var localIdentifier: String { "geometry" }
    override var mediaType: PHAssetMediaType { .unknown }
    override var pixelWidth: Int { 100 }
    override var pixelHeight: Int { 200 }
}

private final class GeometryPanGesture: UIPanGestureRecognizer {
    override var state: UIGestureRecognizer.State {
        get { .changed }
        set { }
    }

    override func translation(in view: UIView?) -> CGPoint {
        CGPoint(x: 0, y: 30)
    }
}

@MainActor
private final class GeometryAnimatableController: UIViewController, MPViewControllerAnimatable {
    let imageView = MPImageView(frame: .zero)
    weak var referencedView: UIView?
    weak var presenter: UIViewController?
    var onPresentation: (() -> Void)?

    override var presentingViewController: UIViewController? { presenter }

    override func loadView() {
        view = UIView()
        view.addSubview(imageView)
    }

    func presentationAnimationWillStart() {
        guard let referencedView else { return }
        imageView.frame = referencedView.convert(referencedView.bounds, to: view)
    }

    func presentingAnimation() { onPresentation?() }
    func presentationAnimationDidFinish() { }
    func dismissingAnimation() { }
    func dismissalAnimationDidFinish() { }
}

@MainActor
private final class GeometryTransitionContext: NSObject, UIViewControllerContextTransitioning {
    let containerView: UIView
    let from: UIViewController
    let to: UIViewController
    let destinationFrame: CGRect
    var isAnimated: Bool { false }
    var isInteractive: Bool { false }
    var transitionWasCancelled: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .custom }
    var targetTransform: CGAffineTransform { .identity }

    init(from: UIViewController, to: UIViewController, container: UIView, destinationFrame: CGRect) {
        self.from = from
        self.to = to
        self.containerView = container
        self.destinationFrame = destinationFrame
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        key == .from ? from : to
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        key == .from ? from.view : to.view
    }

    func initialFrame(for vc: UIViewController) -> CGRect { vc.view.frame }
    func finalFrame(for vc: UIViewController) -> CGRect { destinationFrame }
    func updateInteractiveTransition(_ percentComplete: CGFloat) { }
    func finishInteractiveTransition() { }
    func cancelInteractiveTransition() { }
    func pauseInteractiveTransition() { }
    func completeTransition(_ didComplete: Bool) { }
}
