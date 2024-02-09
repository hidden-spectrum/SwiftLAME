![SwiftLAME Light](https://github.com/hidden-spectrum/SwiftLAME/assets/469799/02bfac1f-8d47-4a0a-afd3-5e4c08d99549)

SwiftLAME is a lightweight Swift wrapper around the [open-source LAME project](https://lame.sourceforge.io) for encoding audio files to MP3 format. This project was created to support the MP3 conversion feature of our [Producer Toolkit macOS App](https://hiddenspectrum.io/producer-toolkit).


## Requirements
SwiftLAME has been tested on macOS 12+, and iOS 15+, although older versions are likely supported. Consider contributing a change to Package.swift if you find this to be the case.

## Installation

Add the dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/hidden-spectrum/swiftlame", .upToNextMajor(from: "0.1.0")),
]
```

## Usage

```swift
import SwiftLAME

let progress = Progress()
let lameEncoder = try SwiftLameEncoder(
    sourceUrl: URL("file:///path/to/source/file.wav"), 
    configuration: .init(
        sampleRate: .constant(44100)
        bitrateMode: .constant(320)
        quality: .mp3Best
    ),
    destinationUrl: URL("file:///path/to/destination/file.wav"),
    progress: progress // optional
)
try await lameEncoder.encode(priority: .userInitiated)
```

## Source Codec Support
SwiftLAME supports converting from the following codecs:
- WAV
- AIFF
- Raw PCM


## Notes
- SwiftLAME is still in early alpha. There may be bugs or missing features.

## License
SwiftLAME, like the [LAME project](https://lame.sourceforge.io/license.txt), is distributed under the LGPL License.
