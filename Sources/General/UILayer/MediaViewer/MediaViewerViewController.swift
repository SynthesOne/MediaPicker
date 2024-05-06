//
//  MediaViewerViewController.swift
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
import AVKit
import Photos

protocol MediaPreviewControllerDataSource: AnyObject {
    func photoViewerController(_ photoViewerController: MediaViewerViewController, referencedViewForPhotoModel model: MPPhotoModel) -> UIView?
}

extension MediaPreviewControllerDataSource {
    func photoViewerController(_ photoViewerController: MediaViewerViewController, referencedViewForPhotoModel model: MPPhotoModel) -> UIView? {
        nil
    }
}

protocol MediaPreviewControllerDelegate: AnyObject {
    func toggleSelected(forModel model: MPPhotoModel)
}

extension MediaPreviewControllerDelegate {
    func toggleSelected(forModel model: MPPhotoModel) {}
}

final class MediaViewerViewController: UIViewController, MPViewControllerAnimatable {
    /// Indicates status bar animation style when changing hidden status
    /// Default value if UIStatusBarStyle.fade
    var statusBarAnimationStyle: UIStatusBarAnimation = .fade

    /// Background color of the viewer.
    /// Default value is black.
    var backgroundColor: UIColor = UIColor.black {
        didSet {
            backgroundView.backgroundColor = backgroundColor
        }
    }

    /// This variable sets original frame of image view to animate from
    fileprivate(set) var referenceSize: CGSize = CGSize.zero


    /// This is the image view that is mainly used for the presentation and dismissal effect.
    /// How it animates from the original view to fullscreen and vice versa.
    let imageView: MPImageView = {
        let view = MPImageView(frame: .zero)
        return view
    }()

    /// The view where photo viewer originally animates from.
    /// Provide this correctly so that you can have a nice effect.
    weak var referencedView: UIView? {
        didSet {
            // Unhide old referenced view and hide the new one
            if oldValue !== referencedView {
                oldValue?.isHidden = false
                referencedView?.isHidden = true
            }
        }
    }

    /// Collection view.
    /// This will be used when displaying multiple images.
    fileprivate let collectionView: UICollectionView = {
        let flowLayout = MPCollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.sectionInset = UIEdgeInsets.zero
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.mp.register(MPPhotoPreviewCell.self)
        view.mp.register(MPLivePhotoPreviewCell.self)
        view.mp.register(MPVideoPreviewCell.self)
        view.mp.register(MPGifPreviewCell.self)
        view.backgroundColor = .none
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    
    fileprivate lazy var selectionButton: MPCheckboxButton = {
        let view = MPCheckboxButton(frame: .zero, uiConfig: uiConfig)
        view.selfSize = 32
        view.contentMode = .center
        view.contentVerticalAlignment = .center
        view.increasedInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
        view.isHidden = true
        return view
    }()
    
    var scrollView: UIScrollView {
        collectionView
    }

    /// View used for fading effect during presentation and dismissal animation or when controller is being dragged.
    private let backgroundView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()

    /// Pan gesture for dragging controller
    private var panGestureRecognizer: UIPanGestureRecognizer!

    /// Double tap gesture
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    /// Single tap gesture
    private var singleTapGestureRecognizer: UITapGestureRecognizer!

    /// Transition animator
    /// Customizable if you wish to provide your own transitions.
    private lazy var animator: MPViewerBaseAnimator = MPAnimator()
    
    private var model: [MPPhotoModel]
    private var selectedModels: [MPPhotoModel]
    private var initialIndex: Int
    private var isFirstAppear = true
    private let uiConfig: MPUIConfiguration
    private let generalConfig: MPGeneralConfiguration

    weak var dataSource: MediaPreviewControllerDataSource?
    weak var delegate: MediaPreviewControllerDelegate?
    
    init(referencedView: UIView?, image: UIImage?, model: [MPPhotoModel], selectedModels: [MPPhotoModel], index: Int, uiConfig: MPUIConfiguration, generalConfig: MPGeneralConfiguration) {
        self.model = model
        self.uiConfig = uiConfig
        self.generalConfig = generalConfig
        self.initialIndex = index
        self.selectedModels = selectedModels
        super.init(nibName: nil, bundle: nil)

        transitioningDelegate = self

        imageView.image = image
        if model[index].type == .image {
            MPManager.fetchImage(for: model[index].asset, size: model[index].previewSize, progress: nil, completion: { image, isDegraded in
                UIView.transition(with: self.imageView, duration: 0.15, options: .transitionCrossDissolve, animations: {
                    self.imageView.image = image
                })
            })
        }
        self.referencedView = referencedView

        modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.log("deinit MediaViewerViewController")
    }

    override func viewDidLoad() {
        if let referencedView {
            // Content mode should be identical between image view and reference view
            imageView.contentMode = referencedView.contentMode
        }
        
        //Background view
        view.addSubview(backgroundView)
        backgroundView.alpha = 0
        backgroundView.backgroundColor = backgroundColor

        //Image view
        // Configure this block for changing image size when image changed
        imageView.imageChangeBlock = { [weak self] (image: UIImage?) -> Void in
            // Update image frame whenever image changes and when the imageView is not being visible
            // imageView is only being visible during presentation or dismissal
            // For that reason, we should not update frame of imageView no matter what.
            guard let strongSelf = self, let image, strongSelf.imageView.isHidden else { return }
            strongSelf.imageView.frame.size = strongSelf.imageViewSizeForImage(image)
            strongSelf.imageView.center = strongSelf.view.center
            strongSelf.collectionView.reloadData()
        }

        imageView.frame = frameForReferencedView()
        imageView.clipsToBounds = true

        //Scroll view
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        view.addSubview(imageView)
        view.addSubview(scrollView)
        view.sendSubviewToBack(scrollView)
        view.sendSubviewToBack(imageView)
        view.sendSubviewToBack(backgroundView)
        view.addSubview(selectionButton)
        
        //Set counter and selected state on first appear before displaying
        if let index = selectedModels.firstIndex(where: { $0 == model[initialIndex] }) {
            selectionButton.counter = index + 1
            selectionButton.setIsOn(true, isAnimate: false)
        }
        
        //Tap gesture recognizer
        singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleTapGesture))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.numberOfTouchesRequired = 1
        singleTapGestureRecognizer.delegate = self

        //Pan gesture recognizer
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(_handlePanGesture))
        panGestureRecognizer.maximumNumberOfTouches = 1
        view.isUserInteractionEnabled = true

        //Double tap gesture recognizer
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleDoubleTapGesture))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.numberOfTouchesRequired = 1
        doubleTapGestureRecognizer.delegate = self
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)

        scrollView.addGestureRecognizer(doubleTapGestureRecognizer)
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
        view.addGestureRecognizer(panGestureRecognizer)
        super.viewDidLoad()
        collectionView.dataSource = self
        selectionButton.mp.action({ [weak self] in
            guard let strongSelf = self else { return }
            let index = strongSelf.currentPhotoIndex
            strongSelf.selectionBlock(at: index)
        }, forEvent: .touchUpInside)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        backgroundView.frame = .init(origin: .zero, size: .init(width: view.bounds.width, height: view.bounds.height))
        backgroundView.center = view.center
        
        scrollView.frame = .init(origin: .zero, size: .init(width: view.bounds.width, height: view.bounds.height))
        scrollView.center = view.center

        if UIApplication.shared.mp.isLandscape == true {
            selectionButton.frame = .init(x: view.bounds.width - 40 - view.safeAreaInsets.right, y: view.safeAreaInsets.top + 8, width: 32, height: 32)
        } else {
            selectionButton.frame = .init(x: view.bounds.width - 40, y: view.safeAreaInsets.top + 8, width: 32, height: 32)
        }
        
        // Update iamge view frame everytime view changes frame
        imageView.imageChangeBlock?(imageView.image)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Update layout
        collectionView.collectionViewLayout.mp.as(MPCollectionViewFlowLayout.self)?.currentIndex = currentPhotoIndex
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !animated {
            presentingAnimation()
            presentationAnimationDidFinish()
        } else {
            presentationAnimationWillStart()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Update image view before animation
        updateImageView(scrollView: scrollView)

        super.viewWillDisappear(animated)

        if !animated {
            dismissingAnimation()
            dismissalAnimationDidFinish()
        } else {
            dismissalAnimationWillStart()
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        statusBarAnimationStyle
    }

    //MARK: Private methods
    fileprivate func startAnimation() {
        //Hide reference image view
        referencedView?.isHidden = true

        //Animate to center
        _animateToCenter()
    }

    func _animateToCenter() {
        UIView.animate(withDuration: animator.presentingDuration, animations: {
            self.presentingAnimation()
        }) { (finished) in
            // Presenting animation ended
            self.presentationAnimationDidFinish()
        }
    }

    func _hideImageView(_ imageViewHidden: Bool) {
        // Hide image view should show collection view and vice versa
        imageView.isHidden = imageViewHidden
        scrollView.isHidden = !imageViewHidden
    }

    func _dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @objc func _handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let indexPath = IndexPath(item: currentPhotoIndex, section: 0)
        if let _ = collectionView.mp.cellItem(MPVideoPreviewCell.self, for: indexPath) {
            return
        }
        selectionBlock(at: indexPath.item)
        // Method to override
        //reverseInfoOverlayViewDisplayStatus()
    }

    @objc func _handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
        //hideInfoOverlayView(false)
        let indexPath = IndexPath(item: currentPhotoIndex, section: 0)

        if let cell = collectionView.mp.cellItem(MPPreviewCell.self, for: indexPath) {
            // Double tap
            if let scrollView = cell.scrollView, let imageView = cell.currentImageView {
                if (scrollView.zoomScale == scrollView.minimumZoomScale) {
                    let location = gesture.location(in: view)
                    let center = imageView.convert(location, from: view)

                    // Zoom in
                    cell.minimumZoomScale = 1.0
                    let rect = zoomRect(for: imageView, withScale: scrollView.maximumZoomScale, withCenter: center)
                    cell.scrollView?.zoom(to: rect, animated: true)
                } else {
                    // Zoom out
                    cell.minimumZoomScale = 1.0
                    cell.scrollView?.setZoomScale(scrollView.minimumZoomScale, animated: true)
                }
            }
        }
    }

    private func frameForReferencedView() -> CGRect {
        if let referencedView = referencedView {
            if let superview = referencedView.superview {
                var frame = (superview.convert(referencedView.frame, to: view))

                if abs(frame.size.width - referencedView.frame.size.width) > 1 {
                    // This is workaround for bug in ios 8, everything is double.
                    frame = CGRect(x: frame.origin.x / 2, y: frame.origin.y / 2, width: frame.size.width / 2, height: frame.size.height / 2)
                }

                return frame
            }
        }

        // Work around when there is no reference view, dragging might behave oddly
        // Should be fixed in the future
        let defaultSize: CGFloat = 1
        return CGRect(x: view.frame.midX - defaultSize / 2, y: view.frame.midY - defaultSize / 2, width: defaultSize, height: defaultSize)
    }

    private func currentPhotoIndex(for scrollView: UIScrollView) -> Int {
        if scrollView.frame.width == 0 {
            return 0
        }
        return Int(round(scrollView.contentOffset.x / scrollView.frame.width))
    }

    // Update zoom inside UICollectionViewCell
    fileprivate func _updateZoomScaleForSize(cell: MPPreviewCell, size: CGSize) {
        if let imageView = cell.currentImageView {
            let widthScale = size.width / imageView.bounds.width
            let heightScale = size.height / imageView.bounds.height
            let zoomScale = min(widthScale, heightScale)
            
            cell.maximumZoomScale = zoomScale
        }
    }

    fileprivate func zoomRect(for imageView: UIImageView, withScale scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    @objc func _handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if let gestureView = gesture.view {
            switch gesture.state {
            case .began:
                // Update image view when starting to drag
                updateImageView(scrollView: scrollView)
                
                toggleHiddenStateOverlayViews(true)

                // Hide collection view & display image view
                _hideImageView(false)

            case .changed:
                let translation = gesture.translation(in: gestureView)
                imageView.center = CGPoint(x: view.center.x, y: view.center.y + translation.y)

                //Change opacity of background view based on vertical distance from center
                let yDistance = CGFloat(abs(imageView.center.y - view.center.y))
                var alpha = 1.0 - yDistance / (gestureView.center.y)

                if alpha < 0 {
                    alpha = 0
                }

                backgroundView.alpha = alpha
            
            default:
                // Animate back to center
                if backgroundView.alpha < 0.8 {
                    _dismiss()
                } else {
                    _animateToCenter()
                }
            }
        }
    }

    private func imageViewSizeForImage(_ image: UIImage?) -> CGSize {
        if let image {
            let rect = AVMakeRect(aspectRatio: image.size, insideRect: view.bounds)
            return rect.size
        }

        return CGSize.zero
    }
    
    private func reloadCurrentCell() {
        let cell = collectionView.cellForItem(at: IndexPath(row: currentPhotoIndex, section: 0))
        if let cell = cell?.mp.as(MPGifPreviewCell.self) {
            cell.loadGifWhenCellDisplaying()
        } else if let cell = cell?.mp.as(MPLivePhotoPreviewCell.self) {
            cell.loadLivePhotoData()
        }
    }
    
    private func selectionBlock(at index: Int) {
        let currentSelectCount = selectedModels.count
        let item = model[index]
        if !item.isSelected {
            if generalConfig.maxMediaSelectCount == 1, currentSelectCount > 0  {
                if let selectedIndex = model.firstIndex(where: { $0.isSelected }) {
                    model[selectedIndex].isSelected = false
                    model[index].isSelected = true
                    selectedModels = [model[selectedIndex]]
                    selectionButton.setIsOn(true)
                }
            } else {
                guard canSelectMedia(item, currentSelectCount: currentSelectCount, generalConfig: generalConfig) else { return }
                model[index].isSelected = true
                selectedModels.append(model[index])
                selectionButton.counter = selectedModels.count
                selectionButton.setIsOn(true)
            }
        } else {
            model[index].isSelected = false
            selectedModels.remove(model[index])
            selectionButton.setIsOn(false)
        }
        delegate?.toggleSelected(forModel: model[index])
    }
    
    private func toggleHiddenStateOverlayViews(_ isHidden: Bool) {
        selectionButton.mp.setIsHidden(isHidden, duration: 0.3)
    }

    func presentingAnimation() {
        // Hide reference view
        referencedView?.isHidden = true
        toggleHiddenStateOverlayViews(false)

        // Calculate final frame
        var destinationFrame = CGRect.zero
        destinationFrame.size = imageViewSizeForImage(imageView.image)

        // Animate image view to the center
        imageView.frame = destinationFrame
        imageView.center = view.center

        // Animate background alpha
        backgroundView.alpha = 1.0
    }

    func dismissingAnimation() {
        imageView.frame = frameForReferencedView()
        backgroundView.alpha = 0
    }

    func presentationAnimationDidFinish() {
        if isFirstAppear {
            scrollToPhoto(at: initialIndex, animated: false)
            isFirstAppear = false
        } else {
            _hideImageView(true)
            toggleHiddenStateOverlayViews(false)
        }
    }

    func presentationAnimationWillStart() {
        _hideImageView(false)
    }

    func dismissalAnimationWillStart() {
        _hideImageView(false)
    }

    func dismissalAnimationDidFinish() {
        referencedView?.isHidden = false
    }
    
    func didScrollToPhoto(at index: Int) {
        if let index = selectedModels.firstIndex(where: { $0 == model[index] }) {
            selectionButton.counter = index + 1
            selectionButton.setIsOn(true, isAnimate: false)
        } else {
            selectionButton.setIsOn(false, isAnimate: false)
        }
    }
}

//MARK: - UIViewControllerTransitioningDelegate
extension MediaViewerViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator
    }
}

//MARK: UICollectionViewDataSource
extension MediaViewerViewController: UICollectionViewDataSource {
    var currentPhotoIndex: Int {
        currentPhotoIndex(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        model.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = model[indexPath.item]
        let cell: MPPreviewCell
        
        if generalConfig.allowGif, model.type == .gif {
            cell = collectionView.mp.cell(MPGifPreviewCell.self, for: indexPath)
        } else if generalConfig.allowLivePhoto, model.type == .livePhoto {
            cell = collectionView.mp.cell(MPLivePhotoPreviewCell.self, for: indexPath)
        } else if generalConfig.allowVideo, model.type == .video {
            cell = collectionView.mp.cell(MPVideoPreviewCell.self, for: indexPath)
        } else {
            cell = collectionView.mp.cell(MPPhotoPreviewCell.self, for: indexPath)
        }
        cell.model = model
        return cell
    }
}

//MARK: Open methods
extension MediaViewerViewController {
    func scrollToPhoto(at index: Int, animated: Bool) {
        collectionView.performBatchUpdates({
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }) { _ in
            self.didScrollToPhoto(at: index)
            self.reloadCurrentCell()
            MPMainAsync(after: 0.08) {
                self._hideImageView(true)
            }
        }
    }
}

//MARK: - UIGestureRecognizerDelegate
extension MediaViewerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let view = touch.view {
            return !(view is UIControl)
        }
        return true
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension MediaViewerViewController: UICollectionViewDelegateFlowLayout {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell = collectionView.mp.cellItem(MPPreviewCell.self, for: .init(item: currentPhotoIndex, section: 0)) {
            cell.previewVCScroll()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.mp.as(MPPreviewCell.self)?.willDisplay()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.mp.as(MPPreviewCell.self)?.didEndDisplaying()
        if let index = selectedModels.firstIndex(where: { $0 == model[currentPhotoIndex] }) {
            selectionButton.counter = index + 1
            selectionButton.setIsOn(true, isAnimate: false)
        } else {
            selectionButton.setIsOn(false, isAnimate: false)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let index = currentPhotoIndex
        didScrollToPhoto(at: index)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.frame.size
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateFrameFor(view.frame.size)

        //Disable pan gesture if zoom scale is not 1
        if scrollView.zoomScale != 1 {
            panGestureRecognizer.isEnabled = false
        } else {
            panGestureRecognizer.isEnabled = true
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let index = currentPhotoIndex
            didScrollToPhoto(at: index)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = currentPhotoIndex
        didScrollToPhoto(at: index)
        reloadCurrentCell()
    }

    //MARK: Helpers
    fileprivate func _updateZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let zoomScale = min(widthScale, heightScale)

        scrollView.maximumZoomScale = zoomScale
    }

    fileprivate func zoomRectForScrollView(_ scrollView: UIScrollView, withScale scale: CGFloat, withCenter center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        // The zoom rect is in the content view's coordinates.
        // At a zoom scale of 1.0, it would be the size of the
        // imageScrollView's bounds.
        // As the zoom scale decreases, so more content is visible,
        // the size of the rect grows.
        zoomRect.size.height = scrollView.frame.size.height / scale
        zoomRect.size.width = scrollView.frame.size.width / scale

        // choose an origin so as to get the right center.
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    fileprivate func updateFrameFor(_ size: CGSize) {

        let y = max(0, (size.height - imageView.frame.height) / 2)
        let x = max(0, (size.width - imageView.frame.width) / 2)

        imageView.frame.origin = CGPoint(x: x, y: y)
    }

    // Update image view image
    func updateImageView(scrollView: UIScrollView) {
        let index = currentPhotoIndex

        // Update image view before pan gesture happens
        imageView.image = collectionView.mp.cellItem(MPPreviewCell.self, for: .init(item: index, section: 0))?.currentImage
        
        if let view = dataSource?.photoViewerController(self, referencedViewForPhotoModel: model[index]) {
            referencedView = view
        }
    }
}
