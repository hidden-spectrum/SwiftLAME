
import AVFAudio
import LAME


public struct SwiftLameEncoder {
    
    // MARK: Private
    
    private let configuration: LameConfiguration
    private let destinationUrl: URL
    private let headerSafetyNetByteCount: UInt32 = 7200
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
        let frameCapacity: AVAudioFrameCount = 1024 * 8
        
        guard let sourceAudioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCapacity) else {
            throw SwiftLameError.couldNotCreateAudioPCMBuffer
        }
        guard let outputStream = OutputStream(url: destinationUrl, append: true) else {
            throw SwiftLameError.couldNotCreateOutputStreamTo(url: destinationUrl)
        }
        
        let lame = Lame(for: sourceAudioFile, configuration: configuration)
        
        outputStream.open()
        var position: AVAudioFramePosition = 0
        
        while position < sourceAudioFile.length {
            try sourceAudioFile.read(into: sourceAudioBuffer)
            try encodeFrame(using: lame, from: sourceAudioBuffer, to: outputStream)
            position += AVAudioFramePosition(sourceAudioBuffer.frameLength)
        }
        
        outputStream.close()
    }
    
    private func encodeFrame(
        using lame: Lame,
        from sourceAudioBuffer: AVAudioPCMBuffer,
        to outputStream: OutputStream
    ) throws {
        let sourceChannelData = try sourceAudioBuffer.getChannelData()
        let frameLength = sourceAudioBuffer.frameLength
        let outputBufferSize = frameLength * lame.sourceChannelCount
        var outputBuffer = Data(count: Int(outputBufferSize))
        
        var encodeLength = 0
        
        try outputBuffer.withUnsafeMutableBytes { (rawOutputBufferPointer: UnsafeMutableRawBufferPointer) in
            let boundBuffer = rawOutputBufferPointer.bindMemory(to: UInt8.self)
            guard let baseAddress = boundBuffer.baseAddress else {
                throw SwiftLameError.couldNotGetRawOutputBufferPointerBaseAddress
            }
            
            if frameLength == 0 {
                encodeLength = lame.encodeFlushNoGap(
                    at: baseAddress,
                    outputBufferSize: outputBufferSize
                )
            } else {
                encodeLength = encodeChannelData(
                    sourceChannelData,
                    using: lame,
                    frameLength: frameLength,
                    baseAddress: baseAddress,
                    outputBufferSize: outputBufferSize
                )
            }
            
            outputStream.write(baseAddress, maxLength: encodeLength)
        }
    }
    
    private func encodeChannelData(
        _ channelData: AVAudioChannelData,
        using lame: Lame,
        frameLength: AVAudioFrameCount,
        baseAddress: UnsafeMutablePointer<UInt8>,
        outputBufferSize: UInt32
    ) -> Int {
        switch channelData {
        case .float(let data):
            return lame.encodeBufferIEEEFloat(data: data, frameLength: frameLength, baseAddress: baseAddress, outputBufferSize: outputBufferSize)
        case .int16(let data):
            return lame.encodeBufferInt16(data: data, frameLength: frameLength, baseAddress: baseAddress, outputBufferSize: outputBufferSize)
        case .int32(let data):
            return lame.encodeBufferInt32(data: data, frameLength: frameLength, baseAddress: baseAddress, outputBufferSize: outputBufferSize)
        }
    }
}
