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

final class MPViewController: UIViewController {
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.mp.register(MediaPickerCell.self)
        view.verticalScrollIndicatorInsets.bottom = 52
        view.contentInset.bottom = 52
        view.delegate = self
        return view
    }()
    
    private let albumListNavView: MPAlbumPickerNavView = {
        let view = MPAlbumPickerNavView(title: "Recents", isCenterAlignment: true)
        return view
    }()
    
    private let closeButton = UIBarButtonItem()
    private let footer = MPFooterView()
    private lazy var dataSource = UICollectionViewDiffableDataSource<MPPhotoModel.Section, MPPhotoModel>(collectionView: collectionView, cellProvider: { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
        self?.cellProvider(collectionView: collectionView, indexPath: indexPath, item: item)
    })
    
    private var dataModel: MPModel = .empty
    private var arrModels: [MPPhotoModel] = []
    private var arrSelectedModels: [MPPhotoModel] = [] {
        didSet {
            MPMainAsync { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.arrSelectedModels.count != oldValue.count {
                    strongSelf.footer.setCounter(strongSelf.arrSelectedModels.count)
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
    private var lastSlideIndex: Int?
    private var beginSlideIndexPath: IndexPath?
    private var autoScrollTimer: CADisplayLink?
    private var lastPanUpdateTime = CACurrentMediaTime()
    private lazy var arrSlideIndexPaths: [IndexPath] = []
    private lazy var dicOriSelectStatus: [IndexPath: Bool] = [:]
    private lazy var slideSelectGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(slideSelectAction(_:)))
        pan.delegate = self
        return pan
    }()
    // **
    
    private var showAddPhotoCell: Bool {
        PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited && albumModel.isCameraRoll
    }
    
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
        
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bottomInset = view.safeAreaInsets.bottom == 0 ? 8 : view.safeAreaInsets.bottom
        footer.frame = .init(x: .zero, y: view.frame.maxY - bottomInset - 52, width: view.frame.width, height: 52 + bottomInset)
    }
    
    private func setupSubviews() {
        view.backgroundColor = MPUIConfiguration.default().primaryBackgroundColor
        view.mp.addSubviews(collectionView, footer)
        view.addGestureRecognizer(slideSelectGesture)
    }
    
    private func setupFooterView() {
        footer.onTap = { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.arrSelectedModels.count > 0 {
                
            } else {
                strongSelf.dismiss(animated: true)
            }
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.albumModel.models.isEmpty {
                strongSelf.albumModel.refetchPhotos()
                
                strongSelf.arrModels.removeAll()
                strongSelf.arrModels.append(contentsOf: strongSelf.albumModel.models)
                strongSelf.markSelected(source: &strongSelf.arrModels, selected: &strongSelf.arrSelectedModels)
            } else {
                strongSelf.arrModels.removeAll()
                strongSelf.arrModels.append(contentsOf: strongSelf.albumModel.models)
                strongSelf.markSelected(source: &strongSelf.arrModels, selected: &strongSelf.arrSelectedModels)
            }
            
            MPMainAsync {
                self?.reloadData()
            }
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize: NSCollectionLayoutSize
            
            itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute((environment.container.contentSize.width / 3) - (UIScreenPixel * 2)),
                heightDimension: .fractionalHeight(1.0)
            )
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalWidth(1.0 / 3))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(UIScreenPixel)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = UIScreenPixel
            section.contentInsets = .zero
            
            return section
            
        }, configuration: configuration)
        
        return layout
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: any Hashable) -> UICollectionViewCell {
        let cell = collectionView.mp.cell(MediaPickerCell.self, for: indexPath)
        
        cell.selectedBlock = { [weak self] block in
            guard let strongSelf = self else { return }
            let currentSelectCount = strongSelf.arrSelectedModels.count
            if !strongSelf.arrModels[indexPath.row].isSelected {
                if MPGeneralConfiguration.default().maxMediaSelectCount == 1, currentSelectCount > 0  {
                    if let selectedIndex = strongSelf.arrModels.firstIndex(where: { $0.isSelected }) {
                        strongSelf.arrModels[selectedIndex].isSelected = false
                        strongSelf.arrModels[indexPath.row].isSelected = true
                        strongSelf.arrSelectedModels = [strongSelf.arrModels[indexPath.row]]
                        strongSelf.toggleCellSelection(at: selectedIndex)
                        block(true)
                        strongSelf.refreshCellIndex()
                    }
                } else {
                    guard strongSelf.canSelectMedia(strongSelf.arrModels[indexPath.row], currentSelectCount: currentSelectCount) else { return }
                    strongSelf.arrModels[indexPath.row].isSelected = true
                    strongSelf.arrSelectedModels.append(strongSelf.arrModels[indexPath.row])
                    block(true)
                    strongSelf.refreshCellIndex()
                }
            } else {
                strongSelf.arrModels[indexPath.row].isSelected = false
                strongSelf.arrSelectedModels.remove(strongSelf.arrModels[indexPath.row])
                block(false)
                strongSelf.refreshCellIndex()
            }
        }
        
        if MPUIConfiguration.default().showCounterOnSelectionButton, let index = arrSelectedModels.firstIndex(where: { $0 == arrModels[indexPath.row] }) {
            setCellIndex(cell, showIndexLabel: true, index: index + 1)
        }
        
        cell.model = arrModels[indexPath.row]
        
        return cell
    }
    
    
    // MARK: - Action && Helpers
    private func adopteDetents() {
        if navigationController?.sheetPresentationController?.selectedDetentIdentifier == .medium {
            navigationController?.sheetPresentationController?.animateChanges { [weak self] in
                self?.navigationController?.sheetPresentationController?.selectedDetentIdentifier = .large
            }
        }
    }

    @objc private func slideSelectAction(_ pan: UIPanGestureRecognizer) {
        if pan.state == .ended || pan.state == .cancelled {
            stopAutoScroll()
            beginPanSelect = false
            panSelectType = .none
            arrSlideIndexPaths.removeAll()
            dicOriSelectStatus.removeAll()
            return
        }
        
        let point = pan.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        
        let cell = collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath)
        
        if pan.state == .began {
            beginPanSelect = cell != nil
            
            if beginPanSelect {
                let index = indexPath.row
                
                panSelectType = arrModels[index].isSelected ? .cancel : .select
                beginSlideIndexPath = indexPath
                
                if !arrModels[index].isSelected {
                    if !canSelectMedia(arrModels[indexPath.row], currentSelectCount: arrSelectedModels.count) {
                        panSelectType = .none
                        return
                    }
                    
                    arrModels[index].isSelected = true
                    arrSelectedModels.append(arrModels[index])
                } else if arrModels[index].isSelected {
                    arrModels[index].isSelected = false
                    arrSelectedModels.remove(arrModels[index])
                }
                
                toggleCellSelection(at: index)
                refreshCellIndex()
                lastSlideIndex = indexPath.row
            }
        } else if pan.state == .changed {
            if !beginPanSelect || indexPath.row == lastSlideIndex || panSelectType == .none || cell == nil {
                return
            }
            
            autoScrollWhenSlideSelect(pan)
            
            guard let beginIndexPath = beginSlideIndexPath else {
                return
            }
            lastPanUpdateTime = CACurrentMediaTime()
            
            let visiblePaths = collectionView.indexPathsForVisibleItems
            slideCalculateQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.lastSlideIndex = indexPath.row
                let minIndex = min(indexPath.row, beginIndexPath.row)
                let maxIndex = max(indexPath.row, beginIndexPath.row)
                let minIsBegin = minIndex == beginIndexPath.row
                
                var i = beginIndexPath.row
                while minIsBegin ? i <= maxIndex : i >= minIndex {
                    if i != beginIndexPath.row {
                        let p = IndexPath(row: i, section: 0)
                        if !strongSelf.arrSlideIndexPaths.contains(p) {
                            strongSelf.arrSlideIndexPaths.append(p)
                            strongSelf.dicOriSelectStatus.updateValue(strongSelf.arrModels[i].isSelected, forKey: p)
                        }
                    }
                    i += (minIsBegin ? 1 : -1)
                }
                
                var selectedArrHasChange = false
                
                for path in strongSelf.arrSlideIndexPaths {
                    if !visiblePaths.contains(path) {
                        continue
                    }
                    let index = path.row
                    let inSection = path.row >= minIndex && path.row <= maxIndex
                    
                    if inSection {
                        if strongSelf.panSelectType == .select {
                            if !strongSelf.arrModels[index].isSelected,
                               strongSelf.canSelectMedia(strongSelf.arrModels[index], currentSelectCount: strongSelf.arrSelectedModels.count) {
                                strongSelf.arrModels[index].isSelected = true
                            }
                        } else if strongSelf.panSelectType == .cancel {
                            strongSelf.arrModels[index].isSelected = false
                        }
                    } else {
                        strongSelf.arrModels[index].isSelected = strongSelf.dicOriSelectStatus[path] ?? false
                    }
                    
                    if !strongSelf.arrModels[index].isSelected {
                        if let index = strongSelf.arrSelectedModels.firstIndex(where: { $0 == strongSelf.arrModels[index] }) {
                            strongSelf.arrSelectedModels.remove(at: index)
                            selectedArrHasChange = true
                        }
                    } else {
                        if !strongSelf.arrSelectedModels.contains(where: { $0 == strongSelf.arrModels[index] }) {
                            strongSelf.arrSelectedModels.append(strongSelf.arrModels[index])
                            selectedArrHasChange = true
                        }
                    }
                    
                    MPMainAsync {
                        self?.toggleCellSelection(at: path.row, withModel: self?.arrModels[index])
                    }
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
        guard arrSelectedModels.count < MPGeneralConfiguration.default().maxMediaSelectCount else {
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
        let showIndex = MPUIConfiguration.default().showCounterOnSelectionButton
        
        guard showIndex else { return }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { indexPath in
            guard let cell = collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath) else { return }
            let m = arrModels[indexPath.row]
            
            let arrSel = arrSelectedModels
            var show = false
            var idx = 0
            for (index, selM) in arrSel.enumerated() {
                if m == selM {
                    show = true
                    idx = index + 1
                    break
                }
            }
            setCellIndex(cell, showIndexLabel: show, index: idx)
        }
    }
    
    private func setCellIndex(_ cell: MediaPickerCell?, showIndexLabel: Bool, index: Int) {
        guard MPUIConfiguration.default().showCounterOnSelectionButton else {
            return
        }
        cell?.index = index
    }
    
    private func markSelected(source: inout [MPPhotoModel], selected: inout [MPPhotoModel]) {
        guard !selected.isEmpty else {
            return
        }
        
        var selIds: [String: Bool] = [:]
        var selIdAndIndex: [String: Int] = [:]
        
        for (index, m) in selected.enumerated() {
            selIds[m.id] = true
            selIdAndIndex[m.id] = index
        }
        
        var i = 0
        source.forEach { m in
            if selIds[m.id] == true {
                source[i].isSelected = true
                selected[selIdAndIndex[m.id]!] = source[i]
            } else {
                source[i].isSelected = false
            }
            i += 1
        }
    }
    
    private func toggleCellSelection(at index: Int, withModel model: MPPhotoModel? = nil) {
        let indexPath = IndexPath(item: index, section: 0)
        let cell = collectionView.mp.cellItem(MediaPickerCell.self, for: indexPath)
        if let model {
            cell?.isOn = model.isSelected
        } else {
            cell?.isOn = arrModels[index].isSelected
        }
    }
    
    func canSelectMedia(_ model: MPPhotoModel, currentSelectCount: Int) -> Bool {
        if currentSelectCount >= MPGeneralConfiguration.default().maxMediaSelectCount {
            return false
        }
        
        guard model.type == .video else {
            return true
        }
        
        return true
    }
}

// MARK: - ReloadData
extension MPViewController {
    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<MPPhotoModel.Section, MPPhotoModel> {
        var snapshot = NSDiffableDataSourceSnapshot<MPPhotoModel.Section, MPPhotoModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(arrModels, toSection: .main)
        return snapshot
    }
    
    private func reloadData(withItems items: [MPPhotoModel] = [], isAnimate: Bool = true, completion: (() -> Void)? = nil) {
        guard !items.isEmpty else {
            let snapshot = makeSnapshot()
            dataSource.applySnapshot(snapshot, animated: isAnimate, completion: completion)
            return
        }
        dataSource.reconfig(withSections: [.main], withItems: items, animated: isAnimate, completion: completion)
    }
}

extension MPViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        return
    }
}

// MARK: Photo library change observer
extension MPViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: albumModel.result) else {
            return
        }
        
        MPMainAsync { [weak self] in
            guard let strongSelf = self else { return }
            // Re-displaying the album list after a change requires an update
            strongSelf.hasTakeANewAsset = true
            strongSelf.albumModel.result = changes.fetchResultAfterChanges
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

extension MPViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let pointInCollectionView = gestureRecognizer.location(in: collectionView)
        if collectionView.indexPathForItem(at: pointInCollectionView) == nil {
            return false
        }
        
        return true
    }
}

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
