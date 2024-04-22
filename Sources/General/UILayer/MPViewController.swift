//
//  MPViewController.swift
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
import Photos
import PhotosUI

final class MPViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.mp.register(MediaPickerCell.self)
        view.mp.register(MPCameraCell.self)
        view.delegate = self
        return view
    }()
    
    private let albumListNavView: MPAlbumPickerNavView = {
        let view = MPAlbumPickerNavView(title: Lang.recents, isCenterAlignment: true)
        return view
    }()
    
    private let closeButton = UIBarButtonItem()
    private lazy var footer: MPFooterView = MPFooterView(showAddToolTip: showAddToolTip)
    private lazy var dataSource = UICollectionViewDiffableDataSource<MPModel.Section, MPModel.Item>(collectionView: collectionView, cellProvider: { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
        self?.cellProvider(collectionView: collectionView, indexPath: indexPath, item: item)
    })
    
    private var dataModel: MPModel = .empty
    private var selectedModels: [MPPhotoModel] = [] {
        didSet {
            MPMainAsync { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.selectedModels.count != oldValue.count {
                    strongSelf.footer.setCounter(strongSelf.selectedModels.count)
                }
            }
        }
    }
    
    
    private var albumModel: MPAlbumModel
    private var hasTakeANewAsset = false
    
    // ** Pan select gesture
    private var autoScrollInfo: (direction: AutoScrollDirection, speed: CGFloat) = (.none, 0)
    private var slideCalculateQueue = DispatchQueue(label: "com.mediapicker.slide")
    private var panSelectType: MPViewController.SlideSelectType = .none
    private var beginPanSelect = false
    private var autoScrollTimer: CADisplayLink?
    private var lastPanUpdateTime = CACurrentMediaTime()
    private lazy var slideSelectGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(slideSelectAction(_:)))
        pan.delegate = self
        return pan
    }()
    // **
    
    private var showedSections: [MPModel.Section] = []
    
    private var showAddToolTip: Bool {
        PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited && albumModel.isCameraRoll
    }
    
    private var showCameraCell: Bool {
        MPUIConfiguration.default().showCameraCell && albumModel.isCameraRoll
    }
    
    private var wasCreateSnapshot: Bool = false
    
    var preSelectedResult: (([MPPhotoModel]) -> ())? = nil
    
    
    init(albumModel: MPAlbumModel) {
        self.albumModel = albumModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        cleanTimer()
        Logger.log("deinit MPViewController")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        setupSubviews()
        setupNavigationView()
        setupFooterView()
        loadPhotos()
        firstLoadPhotos()
        registerChangeObserver()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomInset = view.safeAreaInsets.bottom == 0 ? 8 : view.safeAreaInsets.bottom
        let height = footer.intrinsicContentSize.height
        collectionView.verticalScrollIndicatorInsets.bottom = height
        collectionView.contentInset.bottom = height
        footer.frame = .init(x: .zero, y: view.frame.maxY - bottomInset - height, width: view.frame.width, height: height + bottomInset)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reloadData() { [weak self] in
            guard let strongSelf = self, strongSelf.showCameraCell else { return }
            strongSelf.dataModel.setOrinetation(isLandscape: UIApplication.shared.mp.isLandscape == true)
        }
    }
    
    private func setupSubviews() {
        view.backgroundColor = MPUIConfiguration.default().primaryBackgroundColor
        view.mp.addSubviews(collectionView, footer)
        view.addGestureRecognizer(slideSelectGesture)
    }
    
    private func setupFooterView() {
        footer.actionButtonTap = { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.selectedModels.count > 0 {
                strongSelf.preSelectedResult?(strongSelf.selectedModels)
            } else {
                strongSelf.dismissAlert(needDismiss: true)
            }
        }
        
        footer.toolTipButtonTap = { [weak self] in
            guard let strongSelf = self else { return }
            let actionSheet = ActionSheet({
                Action.default(Lang.selectMorePhotos, action: {
                    self?.presentLimitedLibraryPicker()
                })
                Action.default(Lang.changeSettings, action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                })
                Action.cancel(Lang.cancelButton)
            })
            actionSheet.view.tintColor = MPUIConfiguration.default().navigationAppearance.tintColor
            strongSelf.present(actionSheet, animated: true)
        }
    }
    
    private func setupNavigationView() {
        navigationItem.titleView = albumListNavView
        albumListNavView.setMenuTitle(albumModel.title)
        
        let selectAlbumBlock: ((MPAlbumModel) -> ())? = { [weak self] (album) in
            guard let strongSelf = self, strongSelf.albumModel != album  else { return }
            strongSelf.albumModel = album
            strongSelf.albumListNavView.setMenuTitle(album.title)
            strongSelf.albumListNavView.hide()
            strongSelf.loadPhotos()
            if strongSelf.presentedViewController is MPAlbumListViewController {
                strongSelf.presentedViewController?.dismiss(animated: true)
            }
        }
        
        let closeAlbumBlock: (() -> ())? = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.albumListNavView.hide()
        }
        
        albumListNavView.onTap = { [weak self] (view, isShow) in
            guard let strongSelf = self else { return }
            let albumList = MPAlbumListViewController()
            albumList.preferredContentSize = .init(width: 150, height: 240)
            albumList.popoverPresentationController?.sourceView = view.sourceView
            albumList.popoverPresentationController?.permittedArrowDirections = .up
            albumList.selectAlbumBlock = selectAlbumBlock
            albumList.closeBlock = closeAlbumBlock
            strongSelf.present(albumList, animated: true)
        }
    }
    
    private func loadPhotos() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.albumModel.models.isEmpty {
                strongSelf.albumModel.refetchPhotos()
                strongSelf.dataModel = .init(models: strongSelf.albumModel.models, showCameraCell: strongSelf.showCameraCell)
                strongSelf.markSelected()
            } else {
                strongSelf.dataModel = .init(models: strongSelf.albumModel.models, showCameraCell: strongSelf.showCameraCell)
                strongSelf.markSelected()
            }
            
            MPMainAsync {
                self?.dataModel.setOrinetation(isLandscape: UIApplication.shared.mp.isLandscape == true)
                self?.reloadData()
            }
        }
    }
    
    // The first request was at a limit of 30, so you need to re-request the entire album
    /// completionInMain == false, so that the `loadPhotos()` does not switch the context
    private func firstLoadPhotos() {
        MPManager.getCameraRollAlbum(allowSelectImage: MPGeneralConfiguration.default().allowImage, allowSelectVideo: MPGeneralConfiguration.default().allowVideo, completionInMain: false, completion: { [weak self] (album) in
            self?.albumModel = album
            self?.loadPhotos()
        })
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = UIScreenPixel
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            guard let strongSelf = self else { return nil }
            let section = strongSelf.showedSections[sectionIndex]
            var columnCount = 3
            if UIApplication.shared.mp.scene?.interfaceOrientation.isLandscape == true {
                columnCount += 2
            }
            let totalW = strongSelf.view.safeAreaLayoutGuide.layoutFrame.width - CGFloat(columnCount - 1) * UIScreenPixel
            
            switch section {
            case .cameraRoll:
                let itemWidth = totalW / CGFloat(columnCount)
                let cameraGroupHeight = itemWidth * 2 + UIScreenPixel
                
                let cameraItem = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .absolute(itemWidth),
                        heightDimension: .fractionalHeight(1.0)
                    )
                )
                
                let smallItem = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .absolute(itemWidth),
                        heightDimension: .absolute(itemWidth)
                    )
                )
                let hGroupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(itemWidth)
                )
                
                let bigVGroupSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(cameraGroupHeight),
                    heightDimension: .absolute(cameraGroupHeight)
                )
                
                let mosaicGroup: [NSCollectionLayoutItem]
                
                if #available(iOS 16.0, *) {
                    let firstHGroup = NSCollectionLayoutGroup.horizontal(layoutSize: hGroupSize, repeatingSubitem: smallItem, count: columnCount - 1)
                    firstHGroup.interItemSpacing = .fixed(UIScreenPixel)
                    let secondHGroup = NSCollectionLayoutGroup.horizontal(layoutSize: hGroupSize, repeatingSubitem: smallItem, count: columnCount - 1)
                    secondHGroup.interItemSpacing = .fixed(UIScreenPixel)
                    
                    let bigVGroup = NSCollectionLayoutGroup.vertical(layoutSize: bigVGroupSize, subitems: [firstHGroup, secondHGroup])
                    bigVGroup.interItemSpacing = .fixed(UIScreenPixel)
                    
                    mosaicGroup = [
                        cameraItem,
                        bigVGroup
                    ]
                } else {
                    let firstHGroup = NSCollectionLayoutGroup.horizontal(layoutSize: hGroupSize, subitem: smallItem, count: columnCount - 1)
                    firstHGroup.interItemSpacing = .fixed(UIScreenPixel)
                    let secondHGroup = NSCollectionLayoutGroup.horizontal(layoutSize: hGroupSize, subitem: smallItem, count: columnCount - 1)
                    secondHGroup.interItemSpacing = .fixed(UIScreenPixel)
                    
                    let bigVGroup = NSCollectionLayoutGroup.vertical(layoutSize: bigVGroupSize, subitems: [firstHGroup, secondHGroup])
                    bigVGroup.interItemSpacing = .fixed(UIScreenPixel)
                    
                    mosaicGroup = [
                        cameraItem,
                        bigVGroup
                    ]
                }
                
                let cameraGroupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(cameraGroupHeight)
                )
                
                let cameraGroup = NSCollectionLayoutGroup.horizontal(layoutSize: cameraGroupSize, subitems: mosaicGroup)
                cameraGroup.interItemSpacing = .fixed(UIScreenPixel)
                
                let section = NSCollectionLayoutSection(group: cameraGroup)
                section.contentInsets = .zero
                
                return section
                
            case .main:
                let itemWH = totalW / CGFloat(columnCount)
                
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(itemWH),
                    heightDimension: .fractionalHeight(1.0)
                )
                
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(itemWH))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.interItemSpacing = .fixed(UIScreenPixel)
                
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = UIScreenPixel
                section.contentInsets = .zero
                
                return section
            }
            
        }, configuration: configuration)
        
        return layout
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: MPModel.Item) -> UICollectionViewCell {
        switch item {
        case let .media(model):
            let cell = collectionView.mp.cell(MediaPickerCell.self, for: indexPath)
            
            cell.selectedBlock = { [weak self] block in
                guard let strongSelf = self else { return }
                strongSelf.selectionBlock(indexPath: indexPath, escapeBlock: block)
            }
            
            if MPUIConfiguration.default().showCounterOnSelectionButton, let index = selectedModels.firstIndex(where: { $0 == model }) {
                cell.index = index + 1
            }
            
            cell.model = model
            
            return cell
        case .camera(_):
            let cell = collectionView.mp.cell(MPCameraCell.self, for: indexPath)
            cell.startCapture()
            cell.isEnable = selectedModels.count < MPGeneralConfiguration.default().maxMediaSelectCount
            cell.processSampleBuffer = { [weak self] (sampleBuffer, imageBuffer, connection) in
                self?.handleProcessBuffer(sampleBuffer: sampleBuffer, imageBuffer: imageBuffer, connection: connection)
            }
            return cell
        }
    }
    
    
    // MARK: - Action && Helpers
    private func selectionBlock(indexPath: IndexPath, escapeBlock: ((Bool) -> ())? = nil) {
        let currentSelectCount = selectedModels.count
        let item = dataModel.item(indexPath, showCameraCell: showCameraCell)
        if !item.isSelected {
            if MPGeneralConfiguration.default().maxMediaSelectCount == 1, currentSelectCount > 0  {
                if let selectedIndex = dataModel.firstSelectedIndex(showCameraCell: showCameraCell) {
                    dataModel.toggleSelected(indexPath: selectedIndex, showCameraCell: showCameraCell, false)
                    if let selected = dataModel.toggleSelected(indexPath: indexPath, showCameraCell: showCameraCell, true) {
                        selectedModels = [selected]
                    }
                    toggleCellSelection(at: selectedIndex)
                    if let escapeBlock {
                        escapeBlock(true)
                    } else {
                        toggleCellSelection(at: indexPath)
                    }
                    refreshCellIndex()
                }
            } else {
                guard canSelectMedia(item, currentSelectCount: currentSelectCount) else { return }
                if let selected = dataModel.toggleSelected(indexPath: indexPath, showCameraCell: showCameraCell, true) {
                    selectedModels.append(selected)
                }
                if let escapeBlock {
                    escapeBlock(true)
                } else {
                    toggleCellSelection(at: indexPath)
                }
                refreshCellIndex()
            }
        } else {
            if let unselected = dataModel.toggleSelected(indexPath: indexPath, showCameraCell: showCameraCell, false) {
                selectedModels.remove(unselected)
            }
            if let escapeBlock {
                escapeBlock(false)
            } else {
                toggleCellSelection(at: indexPath)
            }
            refreshCellIndex()
        }
        reloadData()
    }
    
    private func adopteDetents() {
        if navigationController?.sheetPresentationController?.selectedDetentIdentifier == .medium {
            navigationController?.sheetPresentationController?.animateChanges { [weak self] in
                self?.navigationController?.sheetPresentationController?.selectedDetentIdentifier = .large
            }
        }
    }
    
    private func registerChangeObserver() {
        PHPhotoLibrary.shared().register(self)
    }
    
    private func presentLimitedLibraryPicker() {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
    }
    
    @objc private func slideSelectAction(_ pan: UIPanGestureRecognizer) {
        if pan.state == .ended || pan.state == .cancelled {
            stopAutoScroll()
            beginPanSelect = false
            panSelectType = .none
            reloadData()
            return
        }
        
        let point = pan.location(in: collectionView)
        
        // Necessary to check that the selection does not start below the footer
        let pointInFooter = pan.location(in: footer)
        
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        let cell = collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath)
        
        if pan.state == .began {
            beginPanSelect = cell != nil && pointInFooter.y < 0
            
            if beginPanSelect {
                panSelectType = dataModel.item(indexPath, showCameraCell: showCameraCell).isSelected ? .cancel : .select
                
                if !dataModel.item(indexPath, showCameraCell: showCameraCell).isSelected {
                    if !canSelectMedia(dataModel.item(indexPath, showCameraCell: showCameraCell), currentSelectCount: selectedModels.count) {
                        panSelectType = .none
                        return
                    }
                    
                    if let selected = dataModel.toggleSelected(indexPath: indexPath, showCameraCell: showCameraCell, true) {
                        selectedModels.append(selected)
                    }
                } else if dataModel.item(indexPath, showCameraCell: showCameraCell).isSelected {
                    if let unselected = dataModel.toggleSelected(indexPath: indexPath, showCameraCell: showCameraCell, false) {
                        selectedModels.remove(unselected)
                    }
                }
                
                toggleCellSelection(at: indexPath)
                refreshCellIndex()
            }
        } else if pan.state == .changed {
            if !beginPanSelect || panSelectType == .none || cell == nil {
                return
            }
            
            autoScrollWhenSlideSelect(pan)
            
            lastPanUpdateTime = CACurrentMediaTime()
            
            slideCalculateQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                var selectedArrHasChange = false
                
                var item = strongSelf.dataModel.item(indexPath, showCameraCell: strongSelf.showCameraCell)
                
                if strongSelf.panSelectType == .select {
                    if !item.isSelected,
                       canSelectMedia(item, currentSelectCount: strongSelf.selectedModels.count) {
                        strongSelf.dataModel.toggleSelected(indexPath: indexPath, showCameraCell: strongSelf.showCameraCell, true)
                        item.isSelected = true
                    }
                } else if strongSelf.panSelectType == .cancel {
                    strongSelf.dataModel.toggleSelected(indexPath: indexPath, showCameraCell: strongSelf.showCameraCell, false)
                    item.isSelected = false
                }
                
                if !item.isSelected {
                    if let index = strongSelf.selectedModels.firstIndex(where: { $0 == item }) {
                        strongSelf.selectedModels.remove(at: index)
                        selectedArrHasChange = true
                    }
                } else {
                    if !strongSelf.selectedModels.contains(where: { $0 == item }) {
                        strongSelf.selectedModels.append(strongSelf.dataModel.item(indexPath, showCameraCell: strongSelf.showCameraCell))
                        selectedArrHasChange = true
                    }
                }
                
                MPMainAsync {
                    self?.toggleCellSelection(at: indexPath, withModel: item)
                }
                
                if selectedArrHasChange {
                    MPMainAsync {
                        self?.refreshCellIndex()
                    }
                }
            }
        }
    }
    
    private func autoScrollWhenSlideSelect(_ pan: UIPanGestureRecognizer) {
        guard selectedModels.count < MPGeneralConfiguration.default().maxMediaSelectCount else {
            // Stop auto scroll when reach the max select count.
            stopAutoScroll()
            return
        }
        
        let top: CGFloat = 120
        let bottom: CGFloat = footer.frame.minY - 30
        
        let point = pan.location(in: view)
        var diff: CGFloat = 0
        var direction: AutoScrollDirection = .none
        if point.y < top {
            diff = top - point.y
            direction = .top
        } else if point.y > bottom {
            diff = point.y - bottom
            direction = .bottom
        } else {
            stopAutoScroll()
            return
        }
        
        guard diff > 0 else { return }
        
        let s = min(diff, 60) / 60 * 600
        
        autoScrollInfo = (direction, s)
        
        if autoScrollTimer == nil {
            cleanTimer()
            autoScrollTimer = CADisplayLink(target: WeakProxy(target: self), selector: #selector(autoScrollAction))
            autoScrollTimer?.add(to: RunLoop.current, forMode: .common)
        }
    }
    
    @objc private func autoScrollAction() {
        guard autoScrollInfo.direction != .none, slideSelectGesture.state != .possible else {
            stopAutoScroll()
            return
        }
        let duration = CGFloat(autoScrollTimer?.duration ?? 1 / 60)
        if CACurrentMediaTime() - lastPanUpdateTime > 0.2 {
            // Finger may be not moved in slide selection mode
            slideSelectAction(slideSelectGesture)
        }
        let distance = autoScrollInfo.speed * duration
        let offset = collectionView.contentOffset
        let inset = collectionView.contentInset
        if autoScrollInfo.direction == .top, offset.y + inset.top > distance {
            collectionView.contentOffset = CGPoint(x: 0, y: offset.y - distance)
        } else if autoScrollInfo.direction == .bottom, offset.y + collectionView.bounds.height + distance - inset.bottom < collectionView.contentSize.height {
            // *****
            /// An experimental method for resizing during automatic scrolling in a `.medium` detent
            /// If it is not called, it causes scroll to get stuck in `.medium` detent
            // adopteDetents()
            // *****
            collectionView.contentOffset = CGPoint(x: 0, y: offset.y + distance)
        }
    }
    
    private func cleanTimer() {
        autoScrollTimer?.remove(from: RunLoop.current, forMode: .common)
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    private func stopAutoScroll() {
        autoScrollInfo = (.none, 0)
        cleanTimer()
    }
    
    private func refreshCellIndex() {
        refreshCameraCellStatus()
        guard MPUIConfiguration.default().showCounterOnSelectionButton else { return }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { indexPath in
            guard let cell = collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath) else { return }
            let m = dataModel.item(indexPath, showCameraCell: showCameraCell)
            
            var show = false
            var idx = 0
            if let selectedIndex = selectedModels.firstIndex(where: { $0 == m }) {
                show = true
                idx = selectedIndex + 1
            }
            setCellIndex(cell, showIndexLabel: show, index: idx)
        }
    }
    
    private func refreshCameraCellStatus() {
        let count = selectedModels.count
        
        for cell in collectionView.visibleCells {
            if let cell = cell.mp.as(MPCameraCell.self) {
                cell.isEnable = count < MPGeneralConfiguration.default().maxMediaSelectCount
                break
            }
        }
    }
    
    private func setCellIndex(_ cell: MediaPickerCell?, showIndexLabel: Bool, index: Int) {
        guard MPUIConfiguration.default().showCounterOnSelectionButton, showIndexLabel else {
            return
        }
        cell?.index = index
    }
    
    private func markSelected() {
        guard !selectedModels.isEmpty else { return }
        dataModel.markAsSelected(selected: &selectedModels)
    }
    
    private func toggleCellSelection(at indexPath: IndexPath, withModel model: MPPhotoModel? = nil) {
        let cell = collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath)
        if let model {
            cell?.isOn = model.isSelected
        } else {
            cell?.isOn = dataModel.item(indexPath, showCameraCell: showCameraCell).isSelected
        }
    }
    
    private func showCamera() {
        let config = MPGeneralConfiguration.default()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            showAlertView(Lang.сameraUnavailable)
        } else if MPManager.hasCameraAuthority() {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.videoQuality = .typeHigh
            picker.sourceType = .camera
            picker.cameraDevice = .rear
            picker.cameraFlashMode = .auto
            var mediaTypes: [String] = []
            if config.allowImage {
                mediaTypes.append("public.image")
            }
            if config.allowVideo {
                mediaTypes.append("public.movie")
            }
            picker.mediaTypes = mediaTypes
            present(picker, animated: true)
        } else {
            showAlertView(Lang.cameraAccessMessage)
        }
    }
    
    private func showAlertView(_ message: String) {
        MPMainAsync { [weak self] in
            let alert = Alert(message: message, {
                Action.cancel(Lang.ok)
            })
            
            self?.present(alert, animated: true)
        }
    }
    
    private func save(image: UIImage?, videoUrl: URL?) {
        if let image = image {
            MPManager.saveImageToAlbum(image: image) { [weak self] suc, asset in
                if suc, let at = asset {
                    let model = MPPhotoModel(asset: at)
                    self?.handleNewAsset(model)
                } else {
                    self?.showAlertView(Lang.errorSaveImage)
                }
            }
        } else if let videoUrl = videoUrl {
            MPManager.saveVideoToAlbum(url: videoUrl) { [weak self] suc, asset in
                if suc, let at = asset {
                    let model = MPPhotoModel(asset: at)
                    self?.handleNewAsset(model)
                } else {
                    self?.showAlertView(Lang.errorSaveVideo)
                }
            }
        }
    }
    
    private func handleNewAsset(_ model: MPPhotoModel) {
        var mutateModel = model
        let config = MPGeneralConfiguration.default()
        
        if config.maxMediaSelectCount > 1 {
            if selectedModels.count < config.maxMediaSelectCount {
                mutateModel.isSelected = true
                selectedModels.append(mutateModel)
            }
        } else if config.maxMediaSelectCount == 1 {
            mutateModel.isSelected = true
            selectedModels = [mutateModel]
        }
    }
    
    private func handleProcessBuffer(sampleBuffer: CMSampleBuffer, imageBuffer: CVImageBuffer, connection: AVCaptureConnection) {
        guard !wasCreateSnapshot else { return }
        wasCreateSnapshot = true
        DispatchQueue.global().async { [weak self] in
            var ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let size = ciImage.extent.size
            ciImage = ciImage.clampedToExtent().applyingGaussianBlur(sigma: 100).cropped(to: CGRect(origin: .zero, size: size))
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let ciContext = CIContext(options: [.workingColorSpace: colorSpace])
            
            if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
                let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
                guard let data = uiImage.jpegData(compressionQuality: 0.6) else { return }
                let url = NSTemporaryDirectory() + "cameraCaptureImage.jpg"
                try? data.write(to: URL(fileURLWithPath: url))
                self?.wasCreateSnapshot = true
            } else {
                self?.wasCreateSnapshot = false
            }
        }
    }
    
    private func showDismissAlertIfNeed() {
        let alert = Alert(message: Lang.cancelSelect, { [weak self] in
            Action.default(Lang.yes, action: {
                self?.dismiss(animated: true)
            })
            Action.cancel(Lang.no)
        })
        
        present(alert, animated: true)
    }
    
    private func dismissAlert(needDismiss: Bool = false) {
        if !selectedModels.isEmpty {
            showDismissAlertIfNeed()
        } else {
            if needDismiss { dismiss(animated: true) }
        }
    }
}

// MARK: - ReloadData
extension MPViewController {
    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<MPModel.Section, MPModel.Item> {
        var snapshot = NSDiffableDataSourceSnapshot<MPModel.Section, MPModel.Item>()
        var itemsOffset = 5
        if UIApplication.shared.mp.isLandscape == true {
            itemsOffset += 4
        }
        
        if showCameraCell {
            if dataModel.items.count <= itemsOffset {
                snapshot.appendSections([.cameraRoll])
                snapshot.appendItems(dataModel.items, toSection: .cameraRoll)
                showedSections = [.cameraRoll]
            } else {
                snapshot.appendSections([.cameraRoll, .main])
                snapshot.appendItems(Array(dataModel.items[0...itemsOffset]), toSection: .cameraRoll)
                snapshot.appendItems(Array(dataModel.items[itemsOffset...]), toSection: .main)
                showedSections = [.cameraRoll, .main]
            }
        } else {
            snapshot.appendSections([.main])
            snapshot.appendItems(dataModel.items, toSection: .main)
            showedSections = [.main]
        }
        return snapshot
    }
    
    private func reloadData(withItems items: [MPModel.Item] = [], isAnimate: Bool = true, completion: (() -> Void)? = nil) {
        guard !items.isEmpty else {
            let snapshot = makeSnapshot()
            dataSource.applySnapshot(snapshot, animated: isAnimate, completion: completion)
            return
        }
        dataSource.reconfig(withSections: [.main], withItems: items, animated: isAnimate, completion: completion)
    }
}

// MARK: - UICollectionViewDelegate
extension MPViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        switch cell {
        case let cameraCell as MPCameraCell:
            if cameraCell.isEnable {
                showCamera()
            }
        case let mediaCell as MediaPickerCell:
            let (allPhoto, index) = dataModel.extractedMedia(forSelectedIndexPath: indexPath, showCameraCell: showCameraCell)
            let preview = MediaViewerViewController(referencedView: mediaCell.referencedView, image: mediaCell.referencedImage, model: allPhoto, selectedModels: selectedModels, index: index)
            preview.dataSource = self
            preview.delegate = self
            present(preview, animated: true)
        default:
            break
        }
    }
}

// MARK: Photo library change observer
extension MPViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        func isChangesCount<T>(changeDetails: PHFetchResultChangeDetails<T>) -> Bool {
            let before = changeDetails.fetchResultBeforeChanges.count
            let after = changeDetails.fetchResultAfterChanges.count
            return before != after
        }
        guard let changes = changeInstance.changeDetails(for: albumModel.result) else {
            return
        }
        
        MPMainAsync { [weak self] in
            guard let strongSelf = self else { return }
            // Re-displaying the album list after a change requires an update
            strongSelf.hasTakeANewAsset = true
            strongSelf.albumModel.result = changes.fetchResultAfterChanges
            for sm in strongSelf.selectedModels {
                let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                if isDelete {
                    strongSelf.selectedModels.remove(sm)
                }
            }
            if changes.hasIncrementalChanges {
                if !changes.removedObjects.isEmpty || !changes.insertedObjects.isEmpty {
                    strongSelf.albumModel.models.removeAll()
                }
                
                strongSelf.loadPhotos()
            } else {
                strongSelf.albumModel.models.removeAll()
                strongSelf.loadPhotos()
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MPViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let pointInCollectionView = gestureRecognizer.location(in: collectionView)
        if collectionView.indexPathForItem(at: pointInCollectionView) == nil {
            return false
        }
        
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MPViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) { [weak self] in
            let image = info[.originalImage] as? UIImage
            let url = info[.mediaURL] as? URL
            self?.save(image: image, videoUrl: url)
        }
    }
}

// MARK: - Slide select & auto scroll states
extension MPViewController {
    private enum SlideSelectType {
        case none
        case select
        case cancel
    }
    
    private enum AutoScrollDirection {
        case none
        case top
        case bottom
    }
}

// MARK: - MediaPreviewControllerDataSource
extension MPViewController: MediaPreviewControllerDataSource {
    func photoViewerController(_ photoViewerController: MediaViewerViewController, referencedViewForPhotoModel model: MPPhotoModel) -> UIView? {
        if let indexPath = dataModel.getIndexPath(forMedia: model) {
            return collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath)?.referencedView
        }
        return nil
    }
}

// MARK: - MediaPreviewControllerDataSource
extension MPViewController: MediaPreviewControllerDelegate {
    func toggleSelected(forModel model: MPPhotoModel) {
        if let indexPath = dataModel.getIndexPath(forMedia: model) {
            selectionBlock(indexPath: indexPath)
        }
    }
}

// MARK: - UISheetPresentationControllerDelegate
extension MPViewController: UISheetPresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if selectedModels.isEmpty {
            return true
        } else {
            // I don't use the presentationControllerDidAttemptToDismiss for call dismissAlert()
            // Because it is not called when user tap from the outside sheet
            dismissAlert()
            return false
        }
    }
}
