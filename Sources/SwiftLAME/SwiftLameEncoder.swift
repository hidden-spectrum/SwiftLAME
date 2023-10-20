
import AVFAudio
import LAME


public struct SwiftLameEncoder {
    
    // MARK: Private
    
    private let configuration: LameConfiguration
    private let destinationUrl: URL
    private let frameCount: AVAudioFrameCount = 1024 * 8
    private let sourceAudioFile: AVAudioFile
    
    // MARK: Lifecycle
    
    public init(sourceUrl: URL, configuration: LameConfiguration, destinationUrl: URL) throws {
        self.configuration = configuration
        self.destinationUrl = destinationUrl
        self.sourceAudioFile = try AVAudioFile(forReading: sourceUrl)
    }
    
    // MARK: Encoding
    
    public func encode(priority: TaskPriority = .medium) async throws {
        try await Task(priority: priority) {
            try _encode()
        }.value
    }
    
    private func _encode() throws {
        let audioFormat = sourceAudioFile.processingFormat
        
        guard let sourceAudioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
            throw SwiftLameError.couldNotCreateAudioPCMBuffer
        }
        guard let outputStream = OutputStream(url: destinationUrl, append: true) else {
            throw SwiftLameError.couldNotCreateOutputStreamTo(url: destinationUrl)
        }
        
        let lame = Lame(for: sourceAudioFile, configuration: configuration)
        
        let bufferCapacity = Int(frameCount * lame.sourceChannelCount)
        var tmpEncodingBuffer = Data(count: bufferCapacity)
        
        outputStream.open()
        var framePosition: AVAudioFramePosition = 0
        
        while framePosition < sourceAudioFile.length {
            try sourceAudioFile.read(into: sourceAudioBuffer)
            try encodeFrame(with: lame, from: sourceAudioBuffer, to: outputStream, using: &tmpEncodingBuffer, currentPosition: framePosition)
            framePosition += AVAudioFramePosition(sourceAudioBuffer.frameLength)
        }
        
        outputStream.close()
    }
    
    private func encodeFrame(
        with lame: Lame,
        from sourceAudioBuffer: AVAudioPCMBuffer,
        to outputStream: OutputStream,
        using temporaryEncodingBuffer: inout Data,
        currentPosition: AVAudioFramePosition
    ) throws {
        let sourceChannelData = try sourceAudioBuffer.getChannelData()
        let frameCount = sourceAudioBuffer.frameLength
        let bufferCapacity = temporaryEncodingBuffer.count
        
        try temporaryEncodingBuffer.withUnsafeMutableBytes { (bufferPointer: UnsafeMutableRawBufferPointer) in
            let memoryBoundBuffer = bufferPointer.bindMemory(to: UInt8.self)
            guard let bufferAddress = memoryBoundBuffer.baseAddress else {
                throw SwiftLameError.couldNotGetRawOutputBufferPointerBaseAddress
            }
            
            let encodeLength = encodeChannelData(
                sourceChannelData,
                with: lame,
                frameCount: frameCount,
                usingBufferAt: bufferAddress,
                capacity: bufferCapacity
            )
            
            outputStream.write(bufferAddress, maxLength: encodeLength)
            
            let isLastFrame = currentPosition + AVAudioFramePosition(sourceAudioBuffer.frameLength) == sourceAudioFile.length
            
            if isLastFrame {
                let finalEncodeLength = lame.finalizeEncoding(
                    usingBufferAt: bufferAddress,
                    with: bufferCapacity
                )
                outputStream.write(bufferAddress, maxLength: finalEncodeLength)
            }
        }
    }
    
    private func encodeChannelData(
        _ channelData: AVAudioChannelData,
        with lame: Lame,
        frameCount: AVAudioFrameCount,
        usingBufferAt bufferAddress: UnsafeMutablePointer<UInt8>,
        capacity: Int
    ) -> Int {
        switch channelData {
        case .float(let data):
            return lame.encodeIEEEFloatData(data, frameCount: frameCount, fillingBufferAt: bufferAddress, with: capacity)
        case .int16(let data):
            return lame.encodeInt16Data(data, frameCount: frameCount, fillingBufferAt: bufferAddress, with: capacity)
        case .int32(let data):
            return lame.encodeInt32Data(data, frameCount: frameCount, fillingBufferAt: bufferAddress, with: capacity)
        }
    }
}
