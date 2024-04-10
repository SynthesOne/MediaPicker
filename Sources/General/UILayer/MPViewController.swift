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
        return view
    }()
    
    private let albulListNavView: MPAlbumPickerNavView = {
        let view = MPAlbumPickerNavView(title: "Recent", isCenterAlignment: true)
        return view
    }()
    
    private lazy var dataSource = UICollectionViewDiffableDataSource<MPPhotoModel.Section, MPPhotoModel>(collectionView: collectionView, cellProvider: cellProvider)
    
    private var arrModels: [MPPhotoModel] = []
    private var albumModel: MPAlbumModel
    private var hasTakeANewAsset = false
    private let uiConfig = MPUIConfiguration.default()
    
    init(albumModel: MPAlbumModel) {
        self.albumModel = albumModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        setupSubviews()
        setupNavigationView()
        loadPhotos()
        
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    private func setupSubviews() {
        view.backgroundColor = uiConfig.primaryBackgroundColor
        view.addSubview(collectionView)
    }
    
    private func setupNavigationView() {
        navigationItem.titleView = albulListNavView
        albulListNavView.setMenuTitle(albumModel.title)
        
        let selectAlbumBlock: ((MPAlbumModel) -> ())? = { [weak self] (album) in
            guard let strongSelf = self, strongSelf.albumModel != album  else { return }
            self?.albumModel = album
            self?.albulListNavView.setMenuTitle(album.title)
            self?.loadPhotos()
        }
        
        albulListNavView.onTap = { [weak self] (view, isShow) in
            guard let strongSelf = self else { return }
            if isShow {
                let albumList = MPAlbumListViewController()
                albumList.preferredContentSize = .init(width: 120, height: 200)
                albumList.popoverPresentationController?.sourceView = view
                albumList.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                albumList.selectAlbumBlock = selectAlbumBlock
                strongSelf.navigationController?.present(albumList, animated: true)
            } else {
                if strongSelf.navigationController?.presentedViewController is MPAlbumListViewController {
                    strongSelf.navigationController?.presentedViewController?.dismiss(animated: true)
                }
            }
        }
    }
    
    private func loadPhotos() {
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.albumModel.models.isEmpty {
                strongSelf.albumModel.refetchPhotos()
                
                strongSelf.arrModels.removeAll()
                strongSelf.arrModels.append(contentsOf: strongSelf.albumModel.models)
            } else {
                strongSelf.arrModels.removeAll()
                strongSelf.arrModels.append(contentsOf: strongSelf.albumModel.models)
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
            
            itemSize = NSCollectionLayoutSize(widthDimension: .absolute(environment.container.contentSize.width/3), heightDimension: .fractionalHeight(1.0))
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(environment.container.contentSize.width/3))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .flexible(0)
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 0
            section.contentInsets = .zero//.init(top: 16, leading: 16, bottom: 80, trailing: 16)
            
            return section
            
        }, configuration: configuration)
        
        return layout
    }
    
    private func cellProvider(collectionView: UICollectionView, indexPath: IndexPath, item: any Hashable) -> UICollectionViewCell {
        let cell = collectionView.mp.cell(MediaPickerCell.self, for: indexPath)
        
        let model: MPPhotoModel
        
        model = arrModels[indexPath.row]
        
        cell.model = model
        
        return cell
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
