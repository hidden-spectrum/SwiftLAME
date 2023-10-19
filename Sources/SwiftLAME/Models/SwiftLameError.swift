//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import Foundation


public enum SwiftLameError: Error {
    case couldNotCreateAudioPCMBuffer
    case couldNotCreateOutputStreamTo(url: URL)
    case couldNotGetRawOutputBufferPointerBaseAddress
    case couldNotReadChannelDataFromPCMBuffer
}
