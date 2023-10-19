//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import AVFAudio


extension AVAudioPCMBuffer {
    func int16ChannelData() -> Data? {gi
        guard let floatData = int16ChannelData else {
            return nil
        }
        
        let totalSamples = Int(frameLength) * Int(format.channelCount)
        
        var outputData = Data(capacity: totalSamples * MemoryLayout<Int16>.size)
            
        for i in 0..<totalSamples {
            var int16Value: Int16 = Int16(floatData[0][i] * 32767.0)
            var buffer = Data()
            withUnsafeBytes(of: &int16Value) { buffer.append(contentsOf: $0) }
            outputData.append(buffer)
        }
        
        return outputData
    }
}
