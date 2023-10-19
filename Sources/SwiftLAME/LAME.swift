//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import AVFAudio
import LAME


enum LAMEError: Error {
    case couldNotReadChannelDataFromPCMBuffer
    case couldNotGetRawOutputBufferPointerBaseAddress
}


public final class LAME {
    
    // MARK: Private
    
    private var lame: lame_t!
    
    // MARK: Lifecycle
    
    public init(for audioFile: AVAudioFile, numberOfChannels: UInt32, bitrateMode: BitrateMode, quality: LAMEQuality, sampleRate: SampleRate) {
        let lame = lame_init()
        lame_set_in_samplerate(lame, Int32(audioFile.processingFormat.sampleRate))
        lame_set_out_samplerate(lame, sampleRate.lameRepresentation)
        lame_set_quality(lame, quality.rawValue)
        lame_set_num_channels(lame, Int32(numberOfChannels))
        bitrateMode.configure(on: lame)
        lame_init_params(lame)
        self.lame = lame
    }
    
    deinit {
        lame_close(lame)
    }
    
    // MARK: Encoding
    
    public func encode(
        from sourceAudioBuffer: AVAudioPCMBuffer,
        to outputStream: OutputStream
    ) throws {
        guard let sourceChannelData = sourceAudioBuffer.floatChannelData else {
            throw LAMEError.couldNotReadChannelDataFromPCMBuffer
        }
        let frameLength = sourceAudioBuffer.frameLength
        let channelCount = sourceAudioBuffer.format.channelCount
        
        let outputBufferSize = 7200 + frameLength * channelCount
        var outputBuffer = Data(count: Int(outputBufferSize))
        var encodeLength: Int32 = 0
        
        try outputBuffer.withUnsafeMutableBytes { (rawOutputBufferPointer: UnsafeMutableRawBufferPointer) in
            let boundBuffer = rawOutputBufferPointer.bindMemory(to: UInt8.self)
            guard let baseAddress = boundBuffer.baseAddress else {
                throw LAMEError.couldNotGetRawOutputBufferPointerBaseAddress
            }
            
            if frameLength == 0 {
                encodeLength = lame_encode_flush_nogap(
                    lame,
                    baseAddress,
                    Int32(outputBufferSize)
                )
            } else {
                encodeLength = lame_encode_buffer_ieee_float(
                    lame, 
                    sourceChannelData.pointee,
                    sourceChannelData.pointee,
                    Int32(frameLength),
                    baseAddress,
                    Int32(outputBufferSize)
                )
                
//                encodeLength = lame_encode_buffer_interleaved(
//                    lame,
//                    sourceChannelData.pointee,
//                    sourceAudioBufferDataSize,
//                    baseAddress,
//                    outputBufferSize
//                )
            }
            
            outputStream.write(baseAddress, maxLength: Int(encodeLength))
        }
    }
}
