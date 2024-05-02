//
//  MPAlbumListViewController.swift
//
//  Created by Валентин Панчишен on 10.04.2024.
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
import Combine

public final class MPAlbumListViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.showsVerticalScrollIndicator = false
        view.mp.register(MPAlbumListCell.self)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.delegate = self
        view.backgroundColor = .none
        return view
    }()
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<MPAlbumModel.Section, MPAlbumModel>(collectionView: collectionView, cellProvider: { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
        self?.cellProvider(collectionView: collectionView, indexPath: indexPath, item: item)
    })
    
    private var arrModels: [MPAlbumModel] = []
    
    private var shouldReloadAlbumList = true
    
    private let generalConfig: MPGeneralConfiguration
    
    let selectAlbumSubject = PassthroughSubject<MPAlbumModel, Never>()
    let closeSubject = PassthroughSubject<Void, Never>()
    
    //var selectAlbumBlock: ((MPAlbumModel) -> ())?
    //var closeBlock: (() -> ())?
    
    public init(generalConfig: MPGeneralConfiguration) {
        self.generalConfig = generalConfig
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        popoverPresentationController?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Logger.log("deinit MPAlbumListViewController")
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
    
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        closeSubject.send()
        //closeBlock?()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard shouldReloadAlbumList else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            MPManager.getPhotoAlbumList(
                generalConfig: self.generalConfig
            ) { albumList in
                self.arrModels = []
                self.arrModels.append(contentsOf: albumList)
                
                self.shouldReloadAlbumList = false
                MPMainAsync {
                    self.reloadData { [weak self] in
                        self?.viewDidLayoutSubviews()
                    }
                }
            }
        }
    }
    
    public override func loadView() {
        super.loadView()
        view.backgroundColor = .none
        setupSubViews()
        PHPhotoLibrary.shared().register(self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        if contentSize.height != 0, contentSize.height < preferredContentSize.height {
            preferredContentSize.height = contentSize.height
        }
    }
    
    private func setupSubViews() {
        view.mp.addSubviews(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let globalConfig = UICollectionViewCompositionalLayoutConfiguration()
        return UICollectionViewCompositionalLayout(
            sectionProvider: { [weak self] (sectionNumber, env) -> NSCollectionLayoutSection? in
                var config = UICollectionLayoutListConfiguration(appearance: .plain)
                config.backgroundColor = .clear
                config.separatorConfiguration.topSeparatorVisibility = .hidden
                config.separatorConfiguration.color = UIColor.mp.borderColor
                let separatorInsets = NSDirectionalEdgeInsets.zero
                config.itemSeparatorHandler = { (indexPath, config) in
                    var mutateCOnfig = config
                    if self?.collectionView.mp.isLastCellIn(indexPath: indexPath) ?? false {
                        mutateCOnfig.bottomSeparatorVisibility = .hidden
                    } else {
                        mutateCOnfig.bottomSeparatorVisibility = .visible
                        mutateCOnfig.bottomSeparatorInsets = separatorInsets
                    }
                    return mutateCOnfig
                }
                let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: env)
                return section
            },
            configuration: globalConfig
        )
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: any Hashable) -> UICollectionViewCell {
        let cell = collectionView.mp.cell(MPAlbumListCell.self, for: indexPath)
        cell.configureCell(model: arrModels[indexPath.row])
        cell.layoutIfNeeded()
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MPAlbumListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        selectAlbumSubject.send(arrModels[indexPath.item])
        //selectAlbumBlock?(arrModels[indexPath.item])
    }
}

// MARK: - ReloadData
extension MPAlbumListViewController {
    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<MPAlbumModel.Section, MPAlbumModel> {
        var snapshot = NSDiffableDataSourceSnapshot<MPAlbumModel.Section, MPAlbumModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(arrModels, toSection: .main)
        return snapshot
    }
    
    private func reloadData(withItems items: [MPAlbumModel] = [], isAnimate: Bool = true, completion: (() -> Void)? = nil) {
        guard !items.isEmpty else {
            let snapshot = makeSnapshot()
            dataSource.applySnapshot(snapshot, animated: isAnimate, completion: completion)
            return
        }
        dataSource.reconfig(withSections: [.main], withItems: items, animated: isAnimate, completion: completion)
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension MPAlbumListViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        shouldReloadAlbumList = true
    }
}
