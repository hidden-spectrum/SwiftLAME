
import AVFAudio
import LAME


public struct SwiftLameEncoder {
    
    // MARK: Private
    
    private let configuration: LameConfiguration
    private let destinationUrl: URL
    private let frameCount: AVAudioFrameCount = 1024 * 8
    private let progress: Progress?
    private let sourceAudioFile: AVAudioFile
    
    // MARK: Lifecycle
    
    public init(sourceUrl: URL, configuration: LameConfiguration, destinationUrl: URL, progress: Progress? = nil) throws {
        self.configuration = configuration
        self.destinationUrl = destinationUrl
        self.progress = progress
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
        let mBytesPerFrame = sourceAudioFile.processingFormat.streamDescription.pointee.mBytesPerFrame
        let bufferCapacity = Int(frameCount * mBytesPerFrame)
        var tmpEncodingBuffer = Data(count: bufferCapacity)
        
        progress?.totalUnitCount = Int64(sourceAudioFile.length)
        
        outputStream.open()
        var position: AVAudioFramePosition = 0
        
        while position < sourceAudioFile.length {
            try sourceAudioFile.read(into: sourceAudioBuffer)
            
            position += AVAudioFramePosition(sourceAudioBuffer.frameLength)
            let isLastFrame = position == sourceAudioFile.length
            
            try encodeFrame(with: lame, from: sourceAudioBuffer, to: outputStream, using: &tmpEncodingBuffer, isLastFrame: isLastFrame)
            
            progress?.completedUnitCount = Int64(position)
        }
        
        outputStream.close()
    }
    
    private func encodeFrame(
        with lame: Lame,
        from sourceAudioBuffer: AVAudioPCMBuffer,
        to outputStream: OutputStream,
        using tmpEncodingBuffer: inout Data,
        isLastFrame: Bool
    ) throws {
        let sourceChannelData = try sourceAudioBuffer.getChannelData()
        let frameCount = sourceAudioBuffer.frameLength
        let bufferCapacity = tmpEncodingBuffer.count
        
        try tmpEncodingBuffer.withUnsafeMutableBytes { (bufferPointer: UnsafeMutableRawBufferPointer) in
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
