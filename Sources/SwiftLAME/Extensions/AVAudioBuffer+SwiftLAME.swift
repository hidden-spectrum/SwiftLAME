//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import AVFAudio


extension AVAudioPCMBuffer {
    func int16ChannelDataFromFloat() -> UnsafePointer<UnsafeMutablePointer<Int16>>? {
        guard let floatData = floatChannelData else {
            return nil
        }
        
        let frameLength = self.frameLength
        let numChannels = format.channelCount
        
        let outerPointer = UnsafeMutablePointer<UnsafeMutablePointer<Int16>>.allocate(capacity: Int(numChannels))
        
        for channel in 0..<Int(numChannels) {
            let innerPointer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(frameLength))
            outerPointer[channel] = innerPointer
            
            for frame in 0..<Int(frameLength) {
                innerPointer[frame] = Int16(floatData[channel][frame] * 32767.0)
            }
        }
        
        return UnsafePointer(outerPointer)
    }
}
