//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import AVFAudio
import LAME


final class Lame {
    
    // MARK: Internal
    
    let isInterleaved: Bool
    let sourceChannelCount: AVAudioChannelCount
    
    // MARK: Private
    
    private let lame: lame_t!
    
    // MARK: Lifecycle
    
    public init(for audioFile: AVAudioFile, configuration: LameConfiguration) {
        let channelCount = audioFile.processingFormat.channelCount
        self.sourceChannelCount = channelCount
        self.isInterleaved = audioFile.processingFormat.isInterleaved
        
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
    
    func encodeBufferIEEEFloat(
        data: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: AVAudioFrameCount
    ) -> Int {
        return encodeBuffer(
            data: data,
            frameLength: frameLength,
            baseAddress: baseAddress,
            outputBufferSize: outputBufferSize,
            interleavedEncoder: { (lame, pcm, nsamples, mp3buf, mp3buf_size) in
                return lame_encode_buffer_interleaved_ieee_float(lame, pcm, nsamples, mp3buf, mp3buf_size)
            },
            nonInterleavedEncoder: lame_encode_buffer_ieee_float
        )
    }
    
    func encodeBufferInt16(
        data: UnsafePointer<UnsafeMutablePointer<Int16>>,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: AVAudioFrameCount
    ) -> Int {
        return encodeBuffer(
            data: data,
            frameLength: frameLength,
            baseAddress: baseAddress,
            outputBufferSize: outputBufferSize,
            interleavedEncoder: lame_encode_buffer_interleaved,
            nonInterleavedEncoder: lame_encode_buffer
        )
    }
    
    func encodeBufferInt32(
        data: UnsafePointer<UnsafeMutablePointer<Int32>>,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: AVAudioFrameCount
    ) -> Int {
        return encodeBuffer(
            data: data,
            frameLength: frameLength,
            baseAddress: baseAddress,
            outputBufferSize: outputBufferSize,
            interleavedEncoder: { (lame, pcm, nsamples, mp3buf, mp3buf_size) in
                return lame_encode_buffer_interleaved_int(lame, pcm, nsamples, mp3buf, mp3buf_size)
            },
            nonInterleavedEncoder: lame_encode_buffer_int
        )
    }
    
    private func encodeBuffer<T>(
        data: UnsafePointer<UnsafeMutablePointer<T>>,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: AVAudioFrameCount,
        interleavedEncoder: (OpaquePointer?, UnsafeMutablePointer<T>, Int32, UnsafeMutablePointer<UInt8>, Int32) -> Int32,
        nonInterleavedEncoder: (OpaquePointer?, UnsafePointer<T>?, UnsafePointer<T>, Int32, UnsafeMutablePointer<UInt8>, Int32) -> Int32
    ) -> Int {
        var encodeLength: Int32
        
        if isInterleaved {
            encodeLength = interleavedEncoder(
                lame,
                data.pointee,
                Int32(frameLength),
                baseAddress,
                Int32(outputBufferSize)
            )
        } else {
            let leftChannel = sourceChannelCount == 2 ? data[0] : data.pointee
            let rightChannel = sourceChannelCount == 2 ? data[1] : data.pointee
            encodeLength = nonInterleavedEncoder(
                lame,
                leftChannel,
                rightChannel,
                Int32(frameLength),
                baseAddress,
                Int32(outputBufferSize)
            )
        }
        
        return Int(encodeLength)
    }
    
    // MARK: Flush
    
    func encodeFlushNoGap(from bufferAddress: UnsafeMutablePointer<UInt8>, outputBufferSize: AVAudioFrameCount) -> Int {
        let encodeLength = lame_encode_flush_nogap(
            lame,
            bufferAddress,
            Int32(outputBufferSize)
        )
        return Int(encodeLength)
    }
}
