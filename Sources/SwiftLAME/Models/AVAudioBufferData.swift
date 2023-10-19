//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import AVFAudio


enum AVAudioChannelData {
    case float(UnsafePointer<UnsafeMutablePointer<Float>>)
    case int16(UnsafePointer<UnsafeMutablePointer<Int16>>)
    case int32(UnsafePointer<UnsafeMutablePointer<Int32>>)
}


extension AVAudioPCMBuffer {
    func getChannelData() throws -> AVAudioChannelData {
        if let floatChannelData {
            return .float(floatChannelData)
        } else if let int16ChannelData {
            return .int16(int16ChannelData)
        } else if let int32ChannelData {
            return .int32(int32ChannelData)
        } else {
            throw SwiftLameError.couldNotReadChannelDataFromPCMBuffer
        }
    }
}
