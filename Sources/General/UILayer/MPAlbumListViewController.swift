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

public final class MPAlbumListViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.showsVerticalScrollIndicator = false
        view.mp.register(MPAlbumListCell.self)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.delegate = self
        return view
    }()
    
    private let blurSubstrate: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: blurEffect)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<MPAlbumModel.Section, MPAlbumModel>(collectionView: collectionView, cellProvider: cellProvider)
    
    private var arrModels: [MPAlbumModel] = []
    
    private var shouldReloadAlbumList = true
    
    var selectAlbumBlock: ((MPAlbumModel) -> ())?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .popover
        popoverPresentationController?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard shouldReloadAlbumList else { return }
        
        DispatchQueue.global().async {
            MPManager.getPhotoAlbumList(
                ascending: false,
                allowSelectImage: MPGeneralConfiguration.default().allowImage,
                allowSelectVideo: MPGeneralConfiguration.default().allowVideo
            ) { [weak self] albumList in
                self?.arrModels = []
                self?.arrModels.append(contentsOf: albumList)
                
                self?.shouldReloadAlbumList = false
                MPMainAsync {
                    self?.reloadData()
                }
            }
        }
    }
    
    public override func loadView() {
        super.loadView()
        setupSubViews()
        PHPhotoLibrary.shared().register(self)
    }
    
    private func setupSubViews() {
        view.mp.addSubviews(blurSubstrate, collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let globalConfig = UICollectionViewCompositionalLayoutConfiguration()
        return UICollectionViewCompositionalLayout(
            sectionProvider: { (sectionNumber, env) -> NSCollectionLayoutSection? in
                var config = UICollectionLayoutListConfiguration(appearance: .sidebar)
                config.backgroundColor = .none
                config.separatorConfiguration.topSeparatorVisibility = .hidden
                config.separatorConfiguration.color = UIColor.mp.borderColor
                config.itemSeparatorHandler = { [weak self] (indexPath, config) in
                    var mutateCOnfig = config
                    var separatorInsets = NSDirectionalEdgeInsets.zero
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
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MPAlbumListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectAlbumBlock?(arrModels[indexPath.item])
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
