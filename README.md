# SwiftColorWheel

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A beautiful, customizable color wheel for iOS in Swift.

<img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/main/screenshot_1.png" alt="Screenshot" width="150"><img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/main/rotatingcolorwheel.gif" alt="Rotating Screenshot" width="150"><img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/main/screenshot_2.png" alt="Screenshot" width="150">


# More related iOS Controls

You may also find the following iOS controls written in Swift interesting:

* [DSWaveformImage](https://github.com/dmrschmidt/DSWaveformImage) - draw an audio file's waveform image
* [QRCode](https://github.com/dmrschmidt/QRCode) - a customizable QR code generator

Also [check it out on CocoaControls](https://www.cocoacontrols.com/controls/swiftcolorwheel).

# Installation

## Swift Package Manager

Just add `https://github.com/dmrschmidt/SwiftColorWheel` and set "Up to Next Major" to "1.4.0":

## Carthage

Simply add the following to your Cartfile and run `carthage update`:

```
github "dmrschmidt/SwiftColorWheel", ~> 1.4
```

# Usage

Either, add a `ColorWheel` or `RotatingColorWheel` as a custom `UIView` subclass to your interface builder. Alternatively, you can of course simply add it programmatically as a subview to any normal `UIView`.

This will already render your color picker. However it doesn't react on your taps yet. For that, set yourself as it's `delegate`. See the very simplified code example below:

```swift
class MyViewController: UIViewController, ColorWheelDelegate {
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

You can modify the look of the color wheel through various exposed properties.

```swift
// Extra padding in points to the view border.
colorWheel.padding = 13.0

// Radius in point of the central color circle (for black & white shades).
colorWheel.centerRadius = 5.0

// Smallest circle radius in point.
colorWheel.minCircleRadius = 1.0

// Largest circle radius in point.
colorWheel.maxCircleRadius = 5.0

// Padding between circles in point.
colorWheel.innerPadding = 3

/**
 Degree by which each row of circles is shifted.
 A value of 0 results in a straight layout of the inner circles.
 A value other than 0 results in a slightly shifted, fractal-ish / flower-ish look.
*/
colorWheel.shiftDegree = 0

// Overall density of inner circles.
colorWheel.density = 1.0

// Stroke color highlighting currently selected color. Set nil to disable highlighting.
// Default is UIColor.white.
colorWheel.highlightStrokeColor = nil
```

In some case (like when a `RotatingColorWheel` is placed inside a `UIScrollView`) you may want to tweak the default gesture handling for the rotation. If you do so, you can get access to the original gesture handler and use it in composition.

```swift
let originalHandler = rotatingWheel.panRecognizer.delegate
yourRetainedHandler = YourTweakedHandler(complementing: originalHandler)
rotatingWheel.panRecognizer.delegate = yourRetainedHandler
rotatingWheel.rotateRecognizer.delegate = yourRetainedHandler
```

`YourTweakedHandler` could then implement `gestureRecognizerShouldBegin(_:)` in conjunction with the originally provided handler.

## See it live in action

SoundCard lets you send postcards with audio messages.

SwiftColorWheel is used to color the waveform derived from the audio message on postcards sent by [SoundCard](https://www.soundcard.io).

Check it out on the [App Store](http://bit.ly/soundcardio).

<img src="https://github.com/dmrschmidt/SwiftColorWheel/blob/main/screenshot_4.png" alt="Screenshot">
