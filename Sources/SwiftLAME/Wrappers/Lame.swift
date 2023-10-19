//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import AVFAudio
import LAME


final class Lame {
    
    // MARK: Internal
    
    let sourceChannelCount: AVAudioChannelCount
    
    // MARK: Private
    
    private let lame: lame_t!
    
    // MARK: Lifecycle
    
    public init(for audioFile: AVAudioFile, configuration: LameConfiguration) {
        let channelCount = audioFile.processingFormat.channelCount
        self.sourceChannelCount = channelCount
        
        let lame = lame_init()
        lame_set_in_samplerate(lame, Int32(audioFile.processingFormat.sampleRate))
        lame_set_out_samplerate(lame, configuration.sampleRate.lameRepresentation)
        lame_set_quality(lame, configuration.quality.rawValue)
        lame_set_num_channels(lame, Int32(channelCount))
        configuration.bitrateMode.configure(on: lame)
        lame_init_params(lame)
        self.lame = lame
    }
    
    deinit {
        lame_close(lame)
    }
    
    // MARK: Encoding
    
    func encodeFlushNoGap(at baseAddress: UnsafeMutablePointer<UInt8>) -> Int {
        let encodeLength = lame_encode_flush_nogap(lame, baseAddress, 0)
        return Int(encodeLength)
    }
    
    func encodeBufferIEEEFloat(
        data: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: AVAudioFrameCount
    ) -> Int {
        let encodeLength = lame_encode_buffer_ieee_float(
            lame,
            data.pointee,
            data.pointee,
            Int32(frameLength),
            baseAddress,
            Int32(outputBufferSize)
        )
        return Int(encodeLength)
    }
    
    func encodeBufferInterleaved(
        data: UnsafePointer<UnsafeMutablePointer<Int16>>,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: AVAudioFrameCount
    ) -> Int {
        let encodeLength = lame_encode_buffer_interleaved(
            lame,
            data.pointee,
            Int32(frameLength),
            baseAddress,
            Int32(outputBufferSize)
        )
        return Int(encodeLength)
    }
}
