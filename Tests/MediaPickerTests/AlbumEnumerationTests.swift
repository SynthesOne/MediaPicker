import XCTest
import Photos
import Combine
import UIKit
import ObjectiveC
@testable import MediaPicker

@MainActor
final class AlbumEnumerationTests: XCTestCase {
    func testChangedLimitedCameraRollStillLoadsTheEntireAlbum() async throws {
        let started = expectation(description: "Full camera roll request started")
        let drained = expectation(description: "First full camera roll completion drained")
        let limitedLoaded = expectation(description: "Changed limited result loaded")
        let fullLoaded = expectation(description: "Photos beyond the preload limit loaded")
        let release = DispatchSemaphore(value: 0)
        let recents = FixtureAlbum("recents", type: .smartAlbum, subtype: .smartAlbumUserLibrary)
        let originalAssets = (0..<25).map { FixtureAsset("asset-\($0)", type: .unknown) }
        let library = FixturePhotoLibrary(smartAlbums: [recents])
        library.assets["recents"] = originalAssets
        library.firstWorkerFetch = FixtureWorkerFetch(started: started, release: release, drained: drained)
        let restore = try installPhotoLibrary(library)
        defer { restore() }

        let initial = album(recents, assets: Array(originalAssets.prefix(20)), cameraRoll: true)
        initial.option.fetchLimit = 20
        let controller = picker(initial, selected: [MPPhotoModel(asset: originalAssets[24])])
        controller.loadViewIfNeeded()
        await fulfillment(of: [started], timeout: 5)

        do {
            library.assets["recents"] = [FixtureAsset("new-asset", type: .unknown)] + originalAssets
            var changed = initial
            changed.result = library.fetchAssets(in: recents, options: initial.option)
            changed.models.removeAll()
            XCTAssertEqual(changed.count, 20)
            XCTAssertFalse(changed.result === initial.result)
            var published = try publishedAlbum(of: controller)
            var didLoadLimited = false
            let limitedObservation = published.projectedValue.sink { album in
                if !didLoadLimited, album.result === changed.result, album.models.count == 20 {
                    didLoadLimited = true
                    limitedLoaded.fulfill()
                }
            }
            defer { limitedObservation.cancel() }
            var selection = try publishedSelection(of: controller)
            var didLoadFull = false
            let selectionObservation = selection.projectedValue.sink { models in
                if !didLoadFull, models.first?.isSelected == true {
                    didLoadFull = true
                    fullLoaded.fulfill()
                }
            }
            defer { selectionObservation.cancel() }

            let presentation = try FixtureAlbumPresentationCapture()
            defer { presentation.restore() }
            // The observer replaces result but retains the preload's fetchLimit.
            try choose(changed, in: controller, presentation: presentation)
            await fulfillment(of: [limitedLoaded], timeout: 5)
            XCTAssertEqual(try mediaIdentifiers(in: controller).count, 20)

            release.signal()
            await fulfillment(of: [drained, fullLoaded], timeout: 5)

            let identifiers = try mediaIdentifiers(in: controller)
            XCTAssertEqual(identifiers.count, 26, "A changed preload must still expand beyond its first 20 photos")
            XCTAssertEqual(identifiers.first, "new-asset")
            XCTAssertTrue(identifiers.contains("asset-24"))
        } catch {
            release.signal()
            await fulfillment(of: [drained], timeout: 5)
            throw error
        }
    }

    func testLateCameraRollDoesNotReplaceAlbumSelectedFromHeader() async throws {
        let started = expectation(description: "Initial camera roll request started")
        let drained = expectation(description: "Initial camera roll completion drained on main")
        let release = DispatchSemaphore(value: 0)
        let recents = FixtureAlbum("recents", title: "Recents", type: .smartAlbum, subtype: .smartAlbumUserLibrary)
        let chosen = FixtureAlbum("chosen", title: "Chosen album", type: .album, subtype: .albumRegular)
        let library = FixturePhotoLibrary(smartAlbums: [recents])
        library.firstWorkerFetch = FixtureWorkerFetch(started: started, release: release, drained: drained)
        let restore = try installPhotoLibrary(library)
        defer { restore() }

        let initial = album(recents, assets: [FixtureAsset("initial", type: .unknown)], cameraRoll: true)
        let target = album(chosen, assets: [FixtureAsset("target", type: .unknown)])
        let controller = picker(initial)
        controller.loadViewIfNeeded()
        var published = try publishedAlbum(of: controller)
        var latestIdentifier: String?
        let observation = published.projectedValue.sink {
            latestIdentifier = $0.collection.localIdentifier
        }
        defer { observation.cancel() }
        await fulfillment(of: [started], timeout: 5)

        do {
            let presentation = try FixtureAlbumPresentationCapture()
            defer { presentation.restore() }
            try choose(target, in: controller, presentation: presentation)
            XCTAssertEqual(latestIdentifier, "chosen")

            release.signal()
            await fulfillment(of: [drained], timeout: 5)

            XCTAssertEqual(latestIdentifier, "chosen", "An old initial request must not undo the user's album choice")
        } catch {
            release.signal()
            await fulfillment(of: [drained], timeout: 5)
            throw error
        }
    }

    func testDistinctAlbumsWithSameNameCountAndCoverBothLoadThroughHeader() async throws {
        let first = FixtureAlbum("album-A", title: "Same name", type: .album, subtype: .albumRegular)
        let second = FixtureAlbum("album-B", title: "Same name", type: .album, subtype: .albumRegular)
        let cover = FixtureAsset("cover", type: .unknown)
        let firstAsset = FixtureAsset("asset-A", type: .unknown)
        let secondAsset = FixtureAsset("asset-B", type: .unknown)
        let firstAlbum = album(first, assets: [firstAsset, cover])
        let secondAlbum = album(second, assets: [secondAsset, cover])
        let drained = expectation(description: "Empty initial camera roll query finished")
        let library = FixturePhotoLibrary()
        library.firstWorkerFetch = FixtureWorkerFetch(drained: drained)
        let restore = try installPhotoLibrary(library)
        defer { restore() }

        let recents = FixtureAlbum("recents", title: "Recents", type: .smartAlbum, subtype: .smartAlbumUserLibrary)
        let controller = picker(
            album(recents, assets: [FixtureAsset("initial", type: .unknown)], cameraRoll: true),
            selected: [MPPhotoModel(asset: firstAsset), MPPhotoModel(asset: secondAsset)]
        )
        let firstLoaded = expectation(description: "First header selection loaded")
        let secondLoaded = expectation(description: "Second header selection loaded")
        var didLoadFirst = false
        var didLoadSecond = false
        controller.loadViewIfNeeded()
        var published = try publishedSelection(of: controller)
        let observation = published.projectedValue.sink { models in
            if !didLoadFirst, models.first(where: { $0.id == "asset-A" })?.isSelected == true {
                didLoadFirst = true
                firstLoaded.fulfill()
            }
            if !didLoadSecond, models.first(where: { $0.id == "asset-B" })?.isSelected == true {
                didLoadSecond = true
                secondLoaded.fulfill()
            }
        }
        defer { observation.cancel() }
        await fulfillment(of: [drained], timeout: 5)

        let presentation = try FixtureAlbumPresentationCapture()
        defer { presentation.restore() }
        try choose(firstAlbum, in: controller, presentation: presentation)
        await fulfillment(of: [firstLoaded], timeout: 5)
        XCTAssertEqual(try mediaIdentifiers(in: controller), ["asset-A", "cover"])

        try choose(secondAlbum, in: controller, presentation: presentation)
        await fulfillment(of: [secondLoaded], timeout: 5)

        XCTAssertEqual(try mediaIdentifiers(in: controller), ["asset-B", "cover"])
    }

    func testIncludesSmartCollectionsBeyondLongExposuresAndKeepsRecentsFirst() throws {
        let videos = FixtureAlbum("videos", title: "Videos", type: .smartAlbum, subtype: .smartAlbumVideos)
        let raw = FixtureAlbum("raw", title: "RAW", type: .smartAlbum, subtype: .smartAlbumRAW)
        let recordings = FixtureAlbum("recordings", title: "Screen recordings", type: .smartAlbum, subtype: .smartAlbumScreenRecordings)
        let recents = FixtureAlbum("recents", title: "Recent photos", type: .smartAlbum, subtype: .smartAlbumUserLibrary)
        let library = FixturePhotoLibrary(smartAlbums: [videos, raw, recordings, recents])
        library.addImage(to: ["videos", "raw", "recordings", "recents"])

        let result = try albums(in: library)

        XCTAssertEqual(result.map { $0.collection.localIdentifier }, ["recents", "videos", "raw", "recordings"])
        XCTAssertEqual(result.map(\.isCameraRoll), [true, false, false, false])
        XCTAssertEqual(result.first?.title, "Recent photos")
    }

    func testIncludesImportedSyncedEventAndFacesAlbumsAlongsideRegularAndSharedAlbums() throws {
        let collections: [FixtureAlbum] = [
            FixtureAlbum("regular", type: .album, subtype: .albumRegular),
            FixtureAlbum("event", type: .album, subtype: .albumSyncedEvent),
            FixtureAlbum("faces", type: .album, subtype: .albumSyncedFaces),
            FixtureAlbum("imported", type: .album, subtype: .albumImported),
            FixtureAlbum("stream", type: .album, subtype: .albumMyPhotoStream),
            FixtureAlbum("synced", type: .album, subtype: .albumSyncedAlbum),
            FixtureAlbum("shared", type: .album, subtype: .albumCloudShared)
        ]
        let library = FixturePhotoLibrary(albums: collections)
        library.addImage(to: collections.map(\.localIdentifier))

        let result = try albums(in: library)

        XCTAssertEqual(result.map { $0.collection.localIdentifier }, ["regular", "event", "faces", "imported", "stream", "synced", "shared"])
    }

    func testDoesNotRepeatTheSameCollectionIdentity() throws {
        let first = FixtureAlbum("same", title: "First title", type: .album, subtype: .albumRegular)
        let duplicate = FixtureAlbum("same", title: "Repeated title", type: .album, subtype: .albumRegular)
        let library = FixturePhotoLibrary(albums: [first, duplicate])
        library.addImage(to: ["same"])

        let result = try albums(in: library)

        XCTAssertEqual(result.map { $0.collection.localIdentifier }, ["same"])
        XCTAssertEqual(result.first?.title, "First title")
    }

    func testMediaFiltersDetermineAlbumCountsAndRemoveEmptyCollections() throws {
        for allowedType in [PHAssetMediaType.image, .video] {
            let library = FixturePhotoLibrary(albums: [
                FixtureAlbum("mixed", type: .album, subtype: .albumRegular),
                FixtureAlbum("empty-after-filter", type: .album, subtype: .albumRegular)
            ])
            library.assets["mixed"] = [
                FixtureAsset("photo", type: .image),
                FixtureAsset("video", type: .video)
            ]
            library.assets["empty-after-filter"] = [
                FixtureAsset("other", type: allowedType == .image ? .video : .image)
            ]
            var config = MPGeneralConfiguration.default()
            config.allowImage = allowedType == .image
            config.allowVideo = allowedType == .video

            let result = try albums(in: library, configuration: config)

            XCTAssertEqual(result.map { $0.collection.localIdentifier }, ["mixed"])
            XCTAssertEqual(result.map(\.count), [1])
            XCTAssertEqual(result.first?.result.firstObject?.mediaType, allowedType)
            XCTAssertEqual(result.first?.option.sortDescriptors?.first?.ascending, false)
        }
    }

    func testDoesNotForceHiddenAssetAccess() throws {
        let hidden = FixtureAlbum("hidden", type: .smartAlbum, subtype: .smartAlbumAllHidden)
        let normal = FixtureAlbum("normal", type: .album, subtype: .albumRegular)
        let library = FixturePhotoLibrary(smartAlbums: [hidden], albums: [normal])
        library.assets["hidden"] = [FixtureAsset("private", type: .image, hidden: true)]
        library.assets["normal"] = [
            FixtureAsset("visible", type: .image),
            FixtureAsset("also-private", type: .image, hidden: true)
        ]

        let result = try albums(in: library)

        XCTAssertEqual(result.map { $0.collection.localIdentifier }, ["normal"])
        XCTAssertEqual(result.map(\.count), [1])
        XCTAssertFalse(library.assetOptions.contains { $0.includeHiddenAssets })
    }

    private func installPhotoLibrary(_ library: FixturePhotoLibrary) throws -> () -> Void {
        let originalCollections = try XCTUnwrap(class_getClassMethod(
            PHAssetCollection.self,
            #selector(PHAssetCollection.fetchAssetCollections(with:subtype:options:))
        ))
        let replacementCollections = try XCTUnwrap(class_getClassMethod(
            PHAssetCollection.self,
            #selector(PHAssetCollection.mp_albumTestsFetchCollections(with:subtype:options:))
        ))
        let originalAssets = try XCTUnwrap(class_getClassMethod(
            PHAsset.self,
            #selector(PHAsset.fetchAssets(in:options:))
        ))
        let replacementAssets = try XCTUnwrap(class_getClassMethod(
            PHAsset.self,
            #selector(PHAsset.mp_albumTestsFetchAssets(in:options:))
        ))
        FixturePhotoLibrary.current = library
        method_exchangeImplementations(originalCollections, replacementCollections)
        method_exchangeImplementations(originalAssets, replacementAssets)
        return {
            method_exchangeImplementations(originalAssets, replacementAssets)
            method_exchangeImplementations(originalCollections, replacementCollections)
            FixturePhotoLibrary.current = nil
        }
    }

    private func albums(
        in library: FixturePhotoLibrary,
        configuration: MPGeneralConfiguration = .default()
    ) throws -> [MPAlbumModel] {
        let restore = try installPhotoLibrary(library)
        defer { restore() }
        var received: [MPAlbumModel]?
        MPManager.getPhotoAlbumList(generalConfig: configuration) { received = $0 }
        return try XCTUnwrap(received)
    }

    private func album(_ collection: FixtureAlbum, assets: [FixtureAsset], cameraRoll: Bool = false) -> MPAlbumModel {
        var model = MPAlbumModel(
            title: collection.localizedTitle ?? "",
            result: FixtureAssetFetchResult(assets.map { $0 as PHAsset }),
            collection: collection,
            option: PHFetchOptions(),
            isCameraRoll: cameraRoll,
            generalConfig: .default()
        )
        model.models = assets.map { MPPhotoModel(asset: $0) }
        return model
    }

    private func picker(_ initial: MPAlbumModel, selected: [MPPhotoModel] = []) -> MPViewController {
        var configuration = MPUIConfiguration.default()
        configuration.showCameraCell = false
        return MPViewController(
            albumModel: initial, selectedResults: selected,
            uiConfig: configuration, generalConfig: .default()
        )
    }

    private func choose(_ album: MPAlbumModel, in controller: MPViewController, presentation: FixtureAlbumPresentationCapture) throws {
        let header = try XCTUnwrap(controller.navigationItem.titleView as? MPAlbumPickerNavView)
        header.albumMenuActionSubject.send((header, true))
        let albumList = try XCTUnwrap(presentation.presented as? MPAlbumListViewController)
        albumList.selectAlbumSubject.send(album)
    }

    private func publishedAlbum(of controller: MPViewController) throws -> Published<MPAlbumModel> {
        let value = Mirror(reflecting: controller).children.first { $0.label == "_albumModel" }?.value
        return try XCTUnwrap(value as? Published<MPAlbumModel>)
    }

    private func publishedSelection(of controller: MPViewController) throws -> Published<[MPPhotoModel]> {
        let value = Mirror(reflecting: controller).children.first { $0.label == "_selectedModels" }?.value
        return try XCTUnwrap(value as? Published<[MPPhotoModel]>)
    }

    private func mediaIdentifiers(in controller: MPViewController) throws -> [String] {
        let value = Mirror(reflecting: controller).children.first { $0.label == "dataModel" }?.value
        return try XCTUnwrap(value as? MPModel).items.compactMap { $0.unwrapped?.id }
    }
}

private final class FixturePhotoLibrary {
    nonisolated(unsafe) static var current: FixturePhotoLibrary?
    let smartAlbums: [PHAssetCollection]
    let albums: [PHAssetCollection]
    var assets: [String: [FixtureAsset]] = [:]
    var assetOptions: [PHFetchOptions] = []
    var firstWorkerFetch: FixtureWorkerFetch?
    private let workerFetchLock = NSLock()
    private var didClaimWorkerFetch = false

    init(smartAlbums: [PHAssetCollection] = [], albums: [PHAssetCollection] = []) {
        self.smartAlbums = smartAlbums
        self.albums = albums
    }

    func addImage(to identifiers: [String]) {
        for identifier in identifiers {
            assets[identifier] = [FixtureAsset("\(identifier)-asset", type: .image)]
        }
    }

    func collections(type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype) -> PHFetchResult<PHAssetCollection> {
        var controlledFetch: FixtureWorkerFetch?
        if !Thread.isMainThread, type == .smartAlbum {
            workerFetchLock.lock()
            if !didClaimWorkerFetch, let firstWorkerFetch {
                didClaimWorkerFetch = true
                controlledFetch = firstWorkerFetch
            }
            workerFetchLock.unlock()
        }
        controlledFetch?.started?.fulfill()
        if let release = controlledFetch?.release {
            _ = release.wait(timeout: .now() + 10)
        }
        let collections = type == .smartAlbum ? smartAlbums : albums
        return FixtureAlbumFetchResult(collections.filter {
            subtype == .any || $0.assetCollectionSubtype == subtype
        }, afterEnumeration: {
            guard let controlledFetch else { return }
            DispatchQueue.main.async { controlledFetch.drained.fulfill() }
        })
    }

    func fetchAssets(in collection: PHAssetCollection, options: PHFetchOptions?) -> PHFetchResult<PHAsset> {
        if let options { assetOptions.append(options) }
        let matching = (assets[collection.localIdentifier] ?? []).filter {
            (options?.includeHiddenAssets == true || !$0.isHidden) &&
            (options?.predicate?.evaluate(with: $0) ?? true)
        }
        let fetchLimit = options?.fetchLimit ?? 0
        let result = fetchLimit > 0 ? Array(matching.prefix(fetchLimit)) : matching
        return FixtureAssetFetchResult(result.map { $0 as PHAsset })
    }
}

private extension PHAssetCollection {
    @objc class func mp_albumTestsFetchCollections(
        with type: PHAssetCollectionType,
        subtype: PHAssetCollectionSubtype,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        guard let library = FixturePhotoLibrary.current else { preconditionFailure("Missing PhotoKit fixture") }
        return library.collections(type: type, subtype: subtype)
    }
}

private extension PHAsset {
    @objc class func mp_albumTestsFetchAssets(
        in collection: PHAssetCollection,
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAsset> {
        guard let library = FixturePhotoLibrary.current else { preconditionFailure("Missing PhotoKit fixture") }
        return library.fetchAssets(in: collection, options: options)
    }
}

private final class FixtureAlbum: PHAssetCollection, @unchecked Sendable {
    private let identifier: String
    private let title: String
    private let type: PHAssetCollectionType
    private let subtype: PHAssetCollectionSubtype

    init(_ identifier: String, title: String? = nil, type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype) {
        self.identifier = identifier
        self.title = title ?? identifier
        self.type = type
        self.subtype = subtype
        super.init()
    }

    override var localIdentifier: String { identifier }
    override var localizedTitle: String? { title }
    override var assetCollectionType: PHAssetCollectionType { type }
    override var assetCollectionSubtype: PHAssetCollectionSubtype { subtype }
}

private final class FixtureAsset: PHAsset, @unchecked Sendable {
    private let identifier: String
    private let type: PHAssetMediaType
    private let hiddenFlag: Bool

    init(_ identifier: String, type: PHAssetMediaType, hidden: Bool = false) {
        self.identifier = identifier
        self.type = type
        self.hiddenFlag = hidden
        super.init()
    }

    override var localIdentifier: String { identifier }
    override var mediaType: PHAssetMediaType { type }
    override var isHidden: Bool { hiddenFlag }
}

private final class FixtureAlbumFetchResult: PHFetchResult<PHAssetCollection>, @unchecked Sendable {
    private let values: [PHAssetCollection]
    private let afterEnumeration: (() -> Void)?

    init(_ values: [PHAssetCollection], afterEnumeration: (() -> Void)? = nil) {
        self.values = values
        self.afterEnumeration = afterEnumeration
        super.init()
    }

    override var count: Int { values.count }
    override var firstObject: PHAssetCollection? { values.first }
    override var lastObject: PHAssetCollection? { values.last }
    override func object(at index: Int) -> PHAssetCollection { values[index] }

    override func enumerateObjects(_ block: @escaping (PHAssetCollection, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        for (index, value) in values.enumerated() {
            block(value, index, &stop)
            if stop.boolValue { break }
        }
        afterEnumeration?()
    }
}


private final class FixtureWorkerFetch: @unchecked Sendable {
    let started: XCTestExpectation?
    let release: DispatchSemaphore?
    let drained: XCTestExpectation

    init(started: XCTestExpectation? = nil, release: DispatchSemaphore? = nil, drained: XCTestExpectation) {
        self.started = started
        self.release = release
        self.drained = drained
    }
}

private final class FixtureAlbumPresentationCapture {
    private let selector: Selector
    private let original: IMP
    private let replacement: IMP
    private let typeEncoding: UnsafePointer<CChar>
    private var restored = false
    private let storage: Storage

    var presented: UIViewController? { storage.presented }

    init() throws {
        let selector = #selector(UIViewController.present(_:animated:completion:))
        self.selector = selector
        let method = try XCTUnwrap(class_getInstanceMethod(MPViewController.self, selector))
        original = method_getImplementation(method)
        typeEncoding = try XCTUnwrap(method_getTypeEncoding(method))
        let storage = Storage()
        self.storage = storage
        let block: @convention(block) (
            UIViewController, UIViewController, Bool, (@convention(block) () -> Void)?
        ) -> Void = { _, presented, _, completion in
            storage.presented = presented
            completion?()
        }
        replacement = imp_implementationWithBlock(block)
        class_replaceMethod(MPViewController.self, selector, replacement, typeEncoding)
    }

    func restore() {
        guard !restored else { return }
        class_replaceMethod(MPViewController.self, selector, original, typeEncoding)
        _ = imp_removeBlock(replacement)
        restored = true
    }

    deinit { restore() }

    private final class Storage {
        var presented: UIViewController?
    }
}

private final class FixtureAssetFetchResult: PHFetchResult<PHAsset>, @unchecked Sendable {
    private let values: [PHAsset]

    init(_ values: [PHAsset]) {
        self.values = values
        super.init()
    }

    override var count: Int { values.count }
    override var firstObject: PHAsset? { values.first }
    override var lastObject: PHAsset? { values.last }
    override func object(at index: Int) -> PHAsset { values[index] }

    override func enumerateObjects(_ block: @escaping (PHAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        for (index, value) in values.enumerated() {
            block(value, index, &stop)
            if stop.boolValue { break }
        }
    }
}
