# SwiftColorWheel

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A beautiful, customizable color wheel for iOS in Swift.

<img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/master/screenshot_1.png" alt="Screenshot" width="150"><img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/master/screenshot_2.png" alt="Screenshot" width="150">

# More related iOS Controls

You may also find the following iOS controls written in Swift interesting:

* [DSWaveformImage](https://github.com/dmrschmidt/DSWaveformImage) - draw an audio file's waveform image
* [QRCode](https://github.com/dmrschmidt/QRCode) - a customizable QR code generator


# Installation

## Carthage

Simply add the following to your Cartfile and run `carthage update`:

```
github "dmrschmidt/SwiftColorWheel", ~> 1.0.0
```

# Usage

Either, add a `ColorWheel` or `RotatingColorWheel` as a custom `UIView` subclass to your interface builder. Alternatively, you can of course simply add it programmatically as a subview to any normal `UIView`.

This will already render your color picker. However it doesn't react on your taps yet. For that, set yourself as it's `delegate`. See the very simplified code example below:

```swift
class MyViewController: UIViewController {
    private var colorWheel: ColorWheel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        colorWheel = ColorWheel(frame: view.frame)
        colorWheel.delegate = self
        view.addSubview(colorWheel)
    }
    
    // MARK: - ColorWheelDelegate
    
    func didSelect(color: UIColor) {
        view.backgroundColor = color
    }
}
```

# Customization

<img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/master/screenshot_3.png" alt="Screenshot" width="250">
