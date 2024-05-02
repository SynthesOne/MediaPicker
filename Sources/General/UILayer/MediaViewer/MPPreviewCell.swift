//
//  MPPreviewCell.swift
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
import Photos
import PhotosUI

class MPPreviewCell: CollectionViewCell {
    var currentImage: UIImage? { nil }
    
    var currentImageView: UIImageView? { nil }
    
    var scrollView: MPScrollView? { nil }
    
    var model: MPPhotoModel! {
        didSet {
            configureCell()
        }
    }
    
    private func correctCurrentZoomScaleIfNeeded() {
        if let scrollView {
            if scrollView.zoomScale < scrollView.minimumZoomScale {
                scrollView.zoomScale = scrollView.minimumZoomScale
            }
            
            if scrollView.zoomScale > scrollView.maximumZoomScale {
                scrollView.zoomScale = scrollView.maximumZoomScale
            }
        }
    }
    
    // default is 1.0
    var minimumZoomScale: CGFloat = 1.0 {
        willSet {
            if currentImage == nil {
                scrollView?.minimumZoomScale = 1.0
            } else {
                scrollView?.minimumZoomScale = newValue
            }
        }

        didSet {
            correctCurrentZoomScaleIfNeeded()
        }
    }

    // default is 3.0.
    var maximumZoomScale: CGFloat = 3.0 {
        willSet {
            if currentImage == nil {
                scrollView?.minimumZoomScale = 1.0
            } else {
                scrollView?.minimumZoomScale = newValue
            }
        }

        didSet {
            correctCurrentZoomScaleIfNeeded()
        }
    }
    
    var generalConfig: MPGeneralConfiguration = .default()
    
    func previewVCScroll() {}
    
    func willDisplay() {}
    
    func didEndDisplaying() {}
    
    func configureCell() {}
    
    func resizeImageView(imageView: UIImageView, asset: PHAsset) {
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        var frame: CGRect = .zero
        
        let viewW = bounds.width
        let viewH = bounds.height
        
        var width = viewW
        
        if UIApplication.shared.mp.isLandscape == true || isIpad {
            let height = viewH
            frame.size.height = height
            
            let imageWHRatio = size.width / size.height
            let viewWHRatio = viewW / viewH
            
            if imageWHRatio > viewWHRatio {
                frame.size.width = floor(height * imageWHRatio)
                if frame.size.width > viewW {
                    frame.size.width = viewW
                    frame.size.height = viewW / imageWHRatio
                }
            } else {
                width = floor(height * imageWHRatio)
                if width < 1 || width.isNaN {
                    width = viewW
                }
                frame.size.width = width
            }
        } else {
            frame.size.width = width
            
            let imageHWRatio = size.height / size.width
            let viewHWRatio = viewH / viewW
            
            if imageHWRatio > viewHWRatio {
                frame.size.height = floor(width * imageHWRatio)
            } else {
                var height = floor(width * imageHWRatio)
                if height < 1 || height.isNaN {
                    height = viewH
                }
                frame.size.height = height
            }
        }
        
        imageView.frame = frame
        
        if UIApplication.shared.mp.isLandscape == true || isIpad {
            if frame.height < viewH {
                imageView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            } else {
                imageView.frame = CGRect(origin: CGPoint(x: (viewW - frame.width) / 2, y: 0), size: frame.size)
            }
        } else {
            if frame.width < viewW || frame.height < viewH {
                imageView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            }
        }
    }
    
    func animateImageFrame(convertTo view: UIView) -> CGRect {
        return .zero
    }
}

// MARK: static image preview cell
class MPPhotoPreviewCell: MPPreviewCell {
    override var currentImage: UIImage? { preview.image }
    
    override var currentImageView: UIImageView? { preview.imageView }
    
    override var scrollView: MPScrollView? { preview.scrollView }
    
    private let preview: MPPreviewView = {
        let view = MPPreviewView()
        return view
    }()
    
    deinit {
        Logger.log("deinit MPPhotoPreviewCell")
    }
    
    override func setupSubviews() {
        preview.generalConfig = generalConfig
        contentView.addSubview(preview)
    }
    
    override func adaptationLayout() {
        preview.frame = bounds
    }
    
    override func didEndDisplaying() {
        preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let rect = preview.scrollView.convert(preview.containerView.frame, to: self)
        return convert(rect, to: view)
    }
    
    override func configureCell() {
        preview.model = model
    }
}

// MARK: gif preview cell
class MPGifPreviewCell: MPPreviewCell {
    override var currentImage: UIImage? { preview.image }
    
    override var currentImageView: UIImageView? { preview.imageView }
    
    override var scrollView: MPScrollView? { preview.scrollView }
    
    private let preview: MPPreviewView = {
        let view = MPPreviewView()
        return view
    }()
    
    deinit {
        Logger.log("deinit MPGifPreviewCell")
    }
    
    override func setupSubviews() {
        preview.generalConfig = generalConfig
        contentView.addSubview(preview)
    }
    
    override func adaptationLayout() {
        preview.frame = bounds
    }
    
    override func previewVCScroll() {
        preview.pauseGif()
    }
    
    override func didEndDisplaying() {
        preview.scrollView.zoomScale = 1
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        let rect = preview.scrollView.convert(preview.containerView.frame, to: self)
        return convert(rect, to: view)
    }
    
    override func configureCell() {
        preview.model = model
    }
    
    func resumeGif() {
        preview.resumeGif()
    }
    
    func pauseGif() {
        preview.pauseGif()
    }
    
    func loadGifWhenCellDisplaying() {
        preview.loadGifData()
    }
}

// MARK: live photo preview cell
class MPLivePhotoPreviewCell: MPPreviewCell {
    override var currentImage: UIImage? {
        return imageView.image
    }
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let livePhotoView: PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private var imageRequestID = PHInvalidImageRequestID
    
    private var livePhotoRequestID = PHInvalidImageRequestID
    
    private var onFetchingLivePhoto = false
    
    private var fetchLivePhotoDone = false
    
    deinit {
        Logger.log("deinit MPLivePhotoPreviewCell")
    }
    
    override func setupSubviews() {
        contentView.addSubview(livePhotoView)
        contentView.addSubview(imageView)
    }
    
    override func adaptationLayout() {
        livePhotoView.frame = bounds
        resizeImageView(imageView: imageView, asset: model.asset)
    }
    
    override func previewVCScroll() {
        livePhotoView.stopPlayback()
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        return convert(imageView.frame, to: view)
    }
    
    override func didEndDisplaying() {
        PHImageManager.default().cancelImageRequest(livePhotoRequestID)
    }
    
    override func configureCell() {
        loadNormalImage()
    }
    
    private func setupUI() {
        contentView.addSubview(livePhotoView)
        contentView.addSubview(imageView)
    }
    
    private func loadNormalImage() {
        if imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
        if livePhotoRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(livePhotoRequestID)
        }
        onFetchingLivePhoto = false
        imageView.isHidden = false
        
        var size = model.previewSize
        size.width /= 4
        size.height /= 4
        
        resizeImageView(imageView: imageView, asset: model.asset)
        imageRequestID = MPManager.fetchImage(for: model.asset, size: size, completion: { image, _ in
            self.imageView.image = image
        })
    }
    
    private func startPlayLivePhoto() {
        imageView.isHidden = true
        livePhotoView.startPlayback(with: .full)
    }
    
    func loadLivePhotoData() {
        guard !onFetchingLivePhoto else {
            if fetchLivePhotoDone {
                startPlayLivePhoto()
            }
            return
        }
        onFetchingLivePhoto = true
        fetchLivePhotoDone = false
        
        livePhotoRequestID = MPManager.fetchLivePhoto(for: model.asset, completion: { livePhoto, _, isDegraded in
            if !isDegraded {
                self.fetchLivePhotoDone = true
                self.livePhotoView.livePhoto = livePhoto
                self.startPlayLivePhoto()
            }
        })
    }
}

// MARK: video preview cell
class MPVideoPreviewCell: MPPreviewCell {
    override var currentImage: UIImage? {
        imageView.image
    }
    
    private let progressView: MPProgressRing = {
        let view = MPProgressRing()
        view.lineWidth = 4
        view.startColor = .white
        view.endColor = .white
        view.isHidden = true
        return view
    }()
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private let playBtn: UIButton = {
        let sConfig = UIImage.SymbolConfiguration(paletteColors: [.white, .black.withAlphaComponent(0.3)])
        var config = UIButton.Configuration.plain()
        config.background.image = UIImage(systemName: "play.circle.fill", withConfiguration: sConfig)
        config.background.imageContentMode = .scaleAspectFill
        let btn = UIButton(configuration: config)
        return btn
    }()
    
    private let singleTapGes = UITapGestureRecognizer()
    
    private let syncErrorLabel: UILabel = {
        let attStr = NSMutableAttributedString()
        let attach = NSTextAttachment()
        attach.bounds = CGRect(x: 0, y: -10, width: 30, height: 30)
        attStr.append(NSAttributedString(attachment: attach))
        let errorText = NSAttributedString(
            string: Lang.сloudError,
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: Font.regular(12)
            ]
        )
        attStr.append(errorText)
        
        let label = UILabel()
        label.attributedText = attStr
        return label
    }()
    
    private var player: AVPlayer?
    
    private var playerView = UIView()
    
    private var playerLayer: AVPlayerLayer?
    
    private var imageRequestID = PHInvalidImageRequestID
    
    private var videoRequestID = PHInvalidImageRequestID
    
    private var onFetchingVideo = false
    
    private var fetchVideoDone = false
    
    private let operationQueue = DispatchQueue(label: "com.mediapicker.MPVideoPreviewCell")
    
    var isPlaying: Bool {
        if player != nil, player?.rate != 0 {
            return true
        }
        return false
    }
    
    deinit {
        cancelDownloadVideo()
        NotificationCenter.default.removeObserver(self)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch { }
        Logger.log("deinit MPVideoPreviewCell")
    }

    override func setupSubviews() {
        contentView.addSubview(playerView)
        contentView.addSubview(imageView)
        contentView.addSubview(syncErrorLabel)
        contentView.addSubview(playBtn)
        contentView.addSubview(progressView)
        contentView.addGestureRecognizer(singleTapGes)
        playBtn.mp.action({ [weak self] in
            self?.playBtnClick()
        }, forEvent: .touchUpInside)
        
        singleTapGes.addTarget(self, action: #selector(playBtnClick))
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    override func adaptationLayout() {
        resizeImageView(imageView: imageView, asset: model.asset)
        playerView.frame = imageView.frame
        playerLayer?.frame = playerView.bounds
        let insets = UIApplication.shared.mp.currentWindow?.safeAreaInsets ?? .zero
        playBtn.frame = CGRect(origin: .zero, size: CGSize(width: 64, height: 64))
        playBtn.center = CGPoint(x: bounds.midX, y: bounds.midY)
        syncErrorLabel.frame = CGRect(x: 10, y: insets.top + 60, width: bounds.width - 20, height: 35)
        progressView.frame = CGRect(x: bounds.width / 2 - 30, y: bounds.height / 2 - 30, width: 60, height: 60)
    }
    
    override func previewVCScroll() {
        if player != nil, player?.rate != 0 {
            pausePlayer(seekToZero: false)
        }
    }
    
    override func willDisplay() {
        fetchVideo()
    }
    
    override func didEndDisplaying() {
        imageView.isHidden = false
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        cancelDownloadVideo()
    }
    
    override func animateImageFrame(convertTo view: UIView) -> CGRect {
        return convert(imageView.frame, to: view)
    }
    
    override func configureCell() {
        imageView.image = nil
        imageView.isHidden = false
        syncErrorLabel.isHidden = true
        player = nil
        if playerLayer?.superlayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        playerLayer = nil
        
        if imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
        if videoRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(videoRequestID)
        }
        
        var size = model.previewSize
        size.width /= 2
        size.height /= 2
        
        resizeImageView(imageView: imageView, asset: model.asset)
        imageRequestID = MPManager.fetchImage(for: model.asset, size: size, completion: { image, _ in
            self.imageView.image = image
        })
    }
    
    private func fetchVideo() {
        videoRequestID = MPManager.fetchVideo(for: model.asset, progress: { progress, _, _, _ in
            self.progressView.isHidden = progress >= 1
            self.progressView.setProgress(Float(progress))
        }, completion: { item, info, isDegraded in
            let error = info?[PHImageErrorKey] as? Error
            let isFetchError = MPManager.isFetchImageError(error)
            if isFetchError {
                self.syncErrorLabel.isHidden = false
                self.playBtn.mp.setIsHidden(true)
            }
            if !isDegraded, item != nil {
                self.fetchVideoDone = true
                self.configurePlayerLayer(item!)
            }
        })
    }
    
    private func configurePlayerLayer(_ item: AVPlayerItem) {
        playBtn.mp.setIsHidden(false)
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        player = AVPlayer(playerItem: item)
        if playerLayer?.superlayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = playerView.bounds
        playerView.layer.insertSublayer(playerLayer!, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playFinish), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    @objc private func playBtnClick() {
        let currentTime = player?.currentItem?.currentTime()
        let duration = player?.currentItem?.duration
        if player?.rate == 0 {
            if currentTime?.value == duration?.value {
                player?.currentItem?.seek(to: CMTimeMake(value: 0, timescale: 1), completionHandler: nil)
            }
            imageView.isHidden = true
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            } catch { }
            player?.play()
            playBtn.mp.setIsHidden(true)
        } else {
            pausePlayer(seekToZero: false)
        }
    }
    
    @objc private func playFinish() {
        pausePlayer(seekToZero: true)
    }
    
    @objc private func appWillResignActive() {
        if player != nil, player?.rate != 0 {
            pausePlayer(seekToZero: false)
        }
    }
    
    private func pausePlayer(seekToZero: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch { }
        player?.pause()
        if seekToZero {
            player?.seek(to: .zero)
            imageView.isHidden = false
        }
        playBtn.mp.setIsHidden(false)
    }
    
    private func cancelDownloadVideo() {
        PHImageManager.default().cancelImageRequest(videoRequestID)
        videoRequestID = PHInvalidImageRequestID
    }
}

// MARK: Class MPPreviewView
final class MPPreviewView: UIView {
    private let progressView: MPProgressRing = {
        let view = MPProgressRing()
        view.lineWidth = 4
        view.startColor = .white
        view.endColor = .white
        view.isHidden = true
        view.backgroundColor = .black.withAlphaComponent(0.3)
        return view
    }()
    
    private var imageRequestID = PHInvalidImageRequestID
    
    private var gifImageRequestID = PHInvalidImageRequestID
    
    private var imageIdentifier = ""
    
    private var onFetchingGif = false
    
    private var fetchGifDone = false
    
    var generalConfig: MPGeneralConfiguration = .default()
    
    let containerView = UIView()
    
    let scrollView: MPScrollView = {
        let view = MPScrollView()
        view.maximumZoomScale = 3
        view.minimumZoomScale = 1
        view.isMultipleTouchEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.delaysContentTouches = false
        return view
    }()
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }
    
    var model: MPPhotoModel! {
        didSet {
            configureView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        progressView.frame = CGRect(x: bounds.width / 2 - 20, y: bounds.height / 2 - 20, width: 40, height: 40)
        scrollView.zoomScale = 1
        resetSubViewSize()
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        addSubview(progressView)
        scrollView.delegate = self
    }
    
    private func configureView() {
        if imageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
        if gifImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(gifImageRequestID)
        }
        
        scrollView.zoomScale = 1
        imageIdentifier = model.id
        
        if generalConfig.allowGif, model.type == .gif {
            loadGifFirstFrame()
        } else {
            loadPhoto()
        }
    }
    
    private func requestPhotoSize(gif: Bool) -> CGSize {
        var size = model.previewSize
        if gif {
            size.width /= 2
            size.height /= 2
        }
        return size
    }
    
    private func loadPhoto() {
        imageRequestID = MPManager.fetchImage(for: model.asset, size: requestPhotoSize(gif: false), progress: { progress, _, _, _ in
            self.progressView.isHidden = progress >= 1
            self.progressView.setProgress(Float(progress))
        }, completion: { image, isDegraded in
            guard self.imageIdentifier == self.model.id else { return }
            self.imageView.image = image
            self.resetSubViewSize()
            if !isDegraded {
                self.progressView.isHidden = true
                self.imageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    private func loadGifFirstFrame() {
        onFetchingGif = false
        fetchGifDone = false
        
        imageRequestID = MPManager.fetchImage(for: model.asset, size: requestPhotoSize(gif: true), completion: { image, _ in
            guard self.imageIdentifier == self.model.id else { return }
            if self.fetchGifDone == false {
                self.imageView.image = image
                self.resetSubViewSize()
            }
        })
    }
    
    func loadGifData() {
        guard !onFetchingGif else {
            if fetchGifDone {
                resumeGif()
            }
            return
        }
        onFetchingGif = true
        fetchGifDone = false
        imageView.layer.speed = 1
        imageView.layer.timeOffset = 0
        imageView.layer.beginTime = 0
        gifImageRequestID = MPManager.fetchOriginalImageData(for: model.asset, progress: { progress, _, _, _ in
            self.progressView.isHidden = progress >= 1
            self.progressView.setProgress(Float(progress))
        }, completion: { data, info, isDegraded in
            guard self.imageIdentifier == self.model.id else {
                return
            }
            
            if !isDegraded {
                self.fetchGifDone = true
                self.imageView.image = UIImage.mp.gif(data: data)
                self.resetSubViewSize()
            }
        })
    }
    
    func resetSubViewSize() {
        let size: CGSize
        if let model {
            size = CGSize(width: model.asset.pixelWidth, height: model.asset.pixelHeight)
        } else {
            size = imageView.image?.size ?? bounds.size
        }
        
        var frame: CGRect = .zero
        
        let viewW = bounds.width
        let viewH = bounds.height
        
        var width = viewW
        
        if UIApplication.shared.mp.isLandscape == true || isIpad {
            let height = viewH
            frame.size.height = height
            
            let imageWHRatio = size.width / size.height
            let viewWHRatio = viewW / viewH
            
            if imageWHRatio > viewWHRatio {
                frame.size.width = floor(height * imageWHRatio)
                if frame.size.width > viewW {
                    frame.size.width = viewW
                    frame.size.height = viewW / imageWHRatio
                }
            } else {
                width = floor(height * imageWHRatio)
                if width < 1 || width.isNaN {
                    width = viewW
                }
                frame.size.width = width
            }
        } else {
            frame.size.width = width
            
            let imageHWRatio = size.height / size.width
            let viewHWRatio = viewH / viewW
            
            if imageHWRatio > viewHWRatio {
                frame.size.width = min(size.width, viewW)
                frame.size.height = floor(frame.size.width * imageHWRatio)
            } else {
                var height = floor(frame.size.width * imageHWRatio)
                if height < 1 || height.isNaN {
                    height = viewH
                }
                frame.size.height = height
            }
        }
        
        if frame.width < frame.height {
            scrollView.maximumZoomScale = max(3, viewW / frame.width)
        } else {
            scrollView.maximumZoomScale = max(3, viewH / frame.height)
        }
        
        containerView.frame = frame
        
        var contenSize: CGSize = .zero
        if UIApplication.shared.mp.isLandscape == true || isIpad {
            contenSize = CGSize(width: width, height: max(viewH, frame.height))
            if frame.height < viewH {
                containerView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            } else {
                containerView.frame = CGRect(origin: CGPoint(x: (viewW - frame.width) / 2, y: 0), size: frame.size)
            }
        } else {
            contenSize = frame.size
            if frame.height < viewH {
                containerView.center = CGPoint(x: viewW / 2, y: viewH / 2)
            } else {
                containerView.frame = CGRect(origin: CGPoint(x: (viewW - frame.width) / 2, y: 0), size: frame.size)
            }
        }
        
        MPMainAsync(after: 0.01) {
            self.scrollView.contentSize = contenSize
            self.imageView.frame = self.containerView.bounds
            self.scrollView.contentOffset = .zero
        }
    }
    
    func resumeGif() {
        guard let m = model, generalConfig.allowGif, m.type == .gif, imageView.layer.speed != 1 else { return }
        
        let pauseTime = imageView.layer.timeOffset
        imageView.layer.speed = 1
        imageView.layer.timeOffset = 0
        imageView.layer.beginTime = 0
        let timeSincePause = imageView.layer.convertTime(CACurrentMediaTime(), from: nil) - pauseTime
        imageView.layer.beginTime = timeSincePause
    }
    
    func pauseGif() {
        guard let m = model, generalConfig.allowGif, m.type == .gif, imageView.layer.speed != 0 else { return }
        
        let pauseTime = imageView.layer.convertTime(CACurrentMediaTime(), from: nil)
        imageView.layer.speed = 0
        imageView.layer.timeOffset = pauseTime
    }
}

extension MPPreviewView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resumeGif()
    }
}
