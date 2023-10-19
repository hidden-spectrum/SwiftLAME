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
    
    public init(for audioFile: AVAudioFile, bitrateMode: BitrateMode, quality: LAMEQuality, sampleRate: SampleRate) {
        let lame = lame_init()
        lame_set_in_samplerate(lame, Int32(audioFile.processingFormat.sampleRate))
        lame_set_out_samplerate(lame, sampleRate.lameRepresentation)
        lame_set_quality(lame, quality.rawValue)
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
        guard let sourceChannelData = sourceAudioBuffer.int16ChannelData else {
            throw LAMEError.couldNotReadChannelDataFromPCMBuffer
        }
        let frameLength = sourceAudioBuffer.frameLength
        let numChannels = sourceAudioBuffer.format.channelCount
        let sourceAudioBufferDataSize = Int32(Int(frameLength) * Int(numChannels) * MemoryLayout<Int16>.size)
        
        let int32FrameLength = Int32(frameLength)
        
        var outputBuffer = Data(count: Int(frameLength))
        let outputBufferSize = Int32(outputBuffer.count)
        var encodeLength: Int32 = 0
        
        try outputBuffer.withUnsafeMutableBytes { rawOutputBufferPointer in
            let boundBuffer = rawOutputBufferPointer.bindMemory(to: UInt8.self)
            guard let baseAddress = boundBuffer.baseAddress else {
                throw LAMEError.couldNotGetRawOutputBufferPointerBaseAddress
            }
            
            if frameLength == 0 {
                encodeLength = lame_encode_flush_nogap(
                    lame,
                    baseAddress,
                    int32FrameLength
                )
            } else {
                encodeLength = lame_encode_buffer_interleaved(
                    lame,
                    sourceChannelData.pointee,
                    sourceAudioBufferDataSize,
                    baseAddress,
                    outputBufferSize
                )
            }
            
            outputStream.write(baseAddress, maxLength: Int(encodeLength))
        }
    }
}
