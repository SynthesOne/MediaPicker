import XCTest
import Combine
import Photos
import UIKit
import ObjectiveC.runtime
@testable import MediaPicker

@MainActor
final class MediaPickerTests: XCTestCase {
    func testAlbumLoadPublishesSelectionOnMainThread() async throws {
        let selected = photo("selected")
        let controller = MPViewController(
            albumModel: album(models: [selected]),
            selectedResults: [selected],
            uiConfig: .default(),
            generalConfig: .default()
        )
        controller.loadViewIfNeeded()
        var published = try publishedSelection(of: controller)
        let selectionReconciled = expectation(description: "Selected album reconciles selection")
        let observation = published.projectedValue
            .filter { $0.first?.duration == "loaded from selected album" }
            .prefix(1)
            .sink { models in
                XCTAssertTrue(
                    Thread.isMainThread,
                    "Live selection must be reconciled on the same thread as user selection"
                )
                XCTAssertEqual(models.map(\.id), ["selected"])
                XCTAssertEqual(models.first?.isSelected, true)
                selectionReconciled.fulfill()
            }
        defer { observation.cancel() }

        let presentation = try AlbumPresentationCapture()
        defer { presentation.restore() }
        let navigationValue = Mirror(reflecting: controller).children.first { $0.label == "albumListNavView" }?.value
        let navigation = try XCTUnwrap(navigationValue as? MPAlbumPickerNavView)
        navigation.albumMenuActionSubject.send((navigation, true))
        let albumList = try XCTUnwrap(presentation.presented as? MPAlbumListViewController)
        var selectedAlbumPhoto = selected
        selectedAlbumPhoto.duration = "loaded from selected album"
        albumList.selectAlbumSubject.send(album(models: [selectedAlbumPhoto], title: "Another album"))

        await fulfillment(of: [selectionReconciled], timeout: 5)
    }

    func testMarkSelectedPreservesSelectionOrderAndModelsOutsideAlbum() {
        let first = photo("first")
        let second = photo("second")
        let third = photo("third")
        let outside = photo("outside")
        var model = MPModel(models: [first, second, third], showCameraCell: true)
        var selected = [second, outside, first]

        model.markAsSelected(selected: &selected)

        XCTAssertEqual(selected.map(\.id), ["second", "outside", "first"])
        XCTAssertEqual(selected.map(\.isSelected), [true, false, true])
        XCTAssertEqual(model.items.compactMap { $0.unwrapped?.id }, ["first", "second", "third"])
        XCTAssertEqual(model.items.compactMap { $0.unwrapped?.isSelected }, [true, true, false])
    }

    func testReconciliationClearsDeselectionWithoutChangingMediaOrder() {
        var first = photo("first")
        first.isSelected = true
        var second = photo("second")
        second.isSelected = true
        var model = MPModel(models: [first, second], showCameraCell: false)
        var selected = [second]

        model.markAsSelected(selected: &selected)

        XCTAssertEqual(selected.map(\.id), ["second"])
        XCTAssertEqual(model.items.compactMap { $0.unwrapped?.id }, ["first", "second"])
        XCTAssertEqual(model.items.compactMap { $0.unwrapped?.isSelected }, [false, true])
    }

    private func publishedSelection(of controller: MPViewController) throws -> Published<[MPPhotoModel]> {
        let value = Mirror(reflecting: controller).children.first { $0.label == "_selectedModels" }?.value
        return try XCTUnwrap(value as? Published<[MPPhotoModel]>)
    }

    private func photo(_ identifier: String) -> MPPhotoModel {
        MPPhotoModel(asset: TestAsset(identifier: identifier))
    }

    private func album(models: [MPPhotoModel], title: String = "Selection test") -> MPAlbumModel {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [], options: nil)
        let collection = PHAssetCollection.transientAssetCollection(with: [], title: title)
        var album = MPAlbumModel(
            title: title,
            result: result,
            collection: collection,
            option: PHFetchOptions(),
            isCameraRoll: false,
            generalConfig: .default()
        )
        album.models = models
        return album
    }
}

private final class AlbumPresentationCapture {
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

    deinit {
        restore()
    }

    private final class Storage {
        var presented: UIViewController?
    }
}

private final class TestAsset: PHAsset {
    private let identifier: String

    init(identifier: String) {
        self.identifier = identifier
        super.init()
    }

    override var localIdentifier: String { identifier }
    override var mediaType: PHAssetMediaType { .unknown }
}
