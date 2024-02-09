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
    
    func encodeIEEEFloatData(
        _ data: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameCount: AVAudioFrameCount,
        fillingBufferAt bufferAddress: UnsafeMutablePointer<UInt8>,
        with capacity: Int
    ) -> Int {
        return encodeData(
            data,
            frameCount: frameCount,
            fillingBufferAt: bufferAddress,
            with: capacity,
            interleavedEncoder: { (lame, pcm, nsamples, mp3buf, mp3buf_size) in
                return lame_encode_buffer_interleaved_ieee_float(lame, pcm, nsamples, mp3buf, mp3buf_size)
            },
            nonInterleavedEncoder: lame_encode_buffer_ieee_float
        )
    }
    
    func encodeInt16Data(
        _ data: UnsafePointer<UnsafeMutablePointer<Int16>>,
        frameCount: AVAudioFrameCount,
        fillingBufferAt bufferAddress: UnsafeMutablePointer<UInt8>,
        with capacity: Int
    ) -> Int {
        return encodeData(
            data,
            frameCount: frameCount,
            fillingBufferAt: bufferAddress,
            with: capacity,
            interleavedEncoder: lame_encode_buffer_interleaved,
            nonInterleavedEncoder: lame_encode_buffer
        )
    }
    
    func encodeInt32Data(
        _ data: UnsafePointer<UnsafeMutablePointer<Int32>>,
        frameCount: AVAudioFrameCount,
        fillingBufferAt bufferAddress: UnsafeMutablePointer<UInt8>,
        with capacity: Int
    ) -> Int {
        return encodeData(
            data,
            frameCount: frameCount,
            fillingBufferAt: bufferAddress,
            with: capacity,
            interleavedEncoder: { (lame, pcm, nsamples, mp3buf, mp3buf_size) in
                return lame_encode_buffer_interleaved_int(lame, pcm, nsamples, mp3buf, mp3buf_size)
            },
            nonInterleavedEncoder: lame_encode_buffer_int
        )
    }
    
    private func encodeData<T>(
        _ data: UnsafePointer<UnsafeMutablePointer<T>>,
        frameCount: AVAudioFrameCount,
        fillingBufferAt bufferAddress: UnsafeMutablePointer<UInt8>,
        with capacity: Int,
        interleavedEncoder: (OpaquePointer?, UnsafeMutablePointer<T>, Int32, UnsafeMutablePointer<UInt8>, Int32) -> Int32,
        nonInterleavedEncoder: (OpaquePointer?, UnsafePointer<T>?, UnsafePointer<T>, Int32, UnsafeMutablePointer<UInt8>, Int32) -> Int32
    ) -> Int {
        var encodeLength: Int32
        
        if isInterleaved {
            encodeLength = interleavedEncoder(
                lame,
                data.pointee,
                Int32(frameCount),
                bufferAddress,
                Int32(capacity)
            )
        } else {
            let leftChannel = sourceChannelCount == 2 ? data[0] : data.pointee
            let rightChannel = sourceChannelCount == 2 ? data[1] : data.pointee
            encodeLength = nonInterleavedEncoder(
                lame,
                leftChannel,
                rightChannel,
                Int32(frameCount),
                bufferAddress,
                Int32(capacity)
            )
        }
        
        return Int(encodeLength)
    }
    
    // MARK: Finalize
    
    func finalizeEncoding(usingBufferAt bufferAddress: UnsafeMutablePointer<UInt8>, with capacity: Int) -> Int {
        let encodeLength = lame_encode_flush(
            lame,
            bufferAddress,
            Int32(capacity)
        )
        return Int(encodeLength)
    }
}
