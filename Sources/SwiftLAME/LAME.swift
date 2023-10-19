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
    
    private let sourceChannelCount: AVAudioChannelCount
    private let headerSafetyNetByteCount: UInt32 = 7200
    
    private let lame: lame_t!
    
    // MARK: Lifecycle
    
    public init(for audioFile: AVAudioFile, sourceChannelCount: AVAudioChannelCount, bitrateMode: BitrateMode, quality: LAMEQuality, sampleRate: SampleRate) {
        let lame = lame_init()
        lame_set_in_samplerate(lame, Int32(audioFile.processingFormat.sampleRate))
        lame_set_out_samplerate(lame, sampleRate.lameRepresentation)
        lame_set_quality(lame, quality.rawValue)
        lame_set_num_channels(lame, Int32(sourceChannelCount))
        bitrateMode.configure(on: lame)
        lame_init_params(lame)
        self.lame = lame
        self.sourceChannelCount = sourceChannelCount
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
        
        let outputBufferSize = headerSafetyNetByteCount + frameLength * sourceChannelCount
        var outputBuffer = Data(count: Int(outputBufferSize))
        var encodeLength: Int = 0
        
        try outputBuffer.withUnsafeMutableBytes { (rawOutputBufferPointer: UnsafeMutableRawBufferPointer) in
            let boundBuffer = rawOutputBufferPointer.bindMemory(to: UInt8.self)
            guard let baseAddress = boundBuffer.baseAddress else {
                throw LAMEError.couldNotGetRawOutputBufferPointerBaseAddress
            }
            
            if frameLength == 0 {
                encodeLength = encodeFlushNoGap(at: baseAddress)
            } else {
                encodeLength = encodeBufferIEEEFloat(
                    data: sourceChannelData,
                    frameLength: frameLength,
                    baseAddress: baseAddress,
                    outputBufferSize: outputBufferSize
                )
            }
            
            outputStream.write(baseAddress, maxLength: encodeLength)
        }
    }
    
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
