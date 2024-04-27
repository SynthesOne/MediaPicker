# MediaPicker

MediaPicker is a lightweight and flexible library for selecting media files from your gallery. It supports normal photos, videos, gifs and livePhoto. The library is written in pure Swift without any third-party solutions. The project was inspired by Telegram with its simplicity and elegance.

## Demo
Please wait while the `.gif` files are loading...

Comon state:          |Selected view:           
:-------------------------:|:-------------------------:
![](Docs/assets/common_state.gif) | ![](Docs/assets/selected_view.gif)
Limited access state:    |Change orientation:
![](Docs/assets/limited_access_state.gif) | ![](Docs/assets/different_orientations.gif)

## Features

- [x] All media type support
- [x] iOS Deployment Target 15.0
- [x] Light/dark mode support
- [x] All orientations support
- [x] Sheet presentation
- [x] Photos Viewer screen, with custom transitions
- [x] High performance, most animations are written in CALayer
- [x] Multilanguage support, ability to add your own language completely
- [x] Slide to select with auto scroll
- [x] iPad support
- [x] Selected assets view with drag and drop reodering

## Todo

- [x] ~~Custom font deploy~~
- [x] ~~Add the ability to customise the presentation style~~
- [ ] More functionality and UI configuration
- [ ] Minimise the presence of static properties and methods as much as possible
- [ ] Ability to replace used icons with custom icons
- [ ] Add Custom camera
- [ ] Write a detailed documentation

## Requirements

MediaPicker requires iOS 15 or above and is compatibile with Swift 5.

## Installation

### Swift Package Manager
MediaPicker is compatible with [Swift Package Manager](https://swift.org/package-manager) and can be integrated via Xcode.
Select the `main` branch or the current release version

## Usage

```swift
import MediaPicker

let mp = MPPresenter(sender: self)
let formatter = ByteCountFormatter()
mp.showMediaPicker(selectedResult: { (assets) in
    assets.forEach {
        print("Example selectedResult size \(String(describing: $0.size))")
        print("Example selectedResult readableUnit \(formatter.string(fromByteCount: Int64($0.size ?? 0)))")
        print("Example selectedResult fullFileName \(String(describing: $0.fullFileName))")
        print("Example selectedResult fileName \(String(describing: $0.fileName))")
        print("Example selectedResult mediaExtension \(String(describing: $0.fileExtension))")
        print("Example selectedResult mimeType \(String(describing: $0.mimeType))")
        print("Example selectedResult mediType \($0.type)")
    }
})
```
Advanced use cases can be seen in the Example App
