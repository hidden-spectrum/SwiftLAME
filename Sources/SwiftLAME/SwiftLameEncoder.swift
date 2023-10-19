
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
    
    public func encode() throws {
        
        // Create a buffer
        let audioFormat = sourceAudioFile.processingFormat
        let frameCapacity: AVAudioFrameCount = 1024 * 8
        
        guard let sourceAudioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCapacity) else {
            throw SwiftLameError.couldNotCreateAudioPCMBuffer
        }
        
        let lame = Lame(for: sourceAudioFile, configuration: configuration)
        
        guard let outputStream = OutputStream(url: destinationUrl, append: true) else {
            throw SwiftLameError.couldNotCreateOutputStreamTo(url: destinationUrl)
        }
        
        outputStream.open()
        var position: AVAudioFramePosition = 0
        
        while position < sourceAudioFile.length {
            do {
                try sourceAudioFile.read(into: sourceAudioBuffer)
                try encodeChunk(using: lame, from: sourceAudioBuffer, to: outputStream)
            } catch {
                print(error)
            }
            
            position += AVAudioFramePosition(sourceAudioBuffer.frameLength)
        }
        
        outputStream.close()
    }
    
    private func encodeChunk(
        using lame: Lame,
        from sourceAudioBuffer: AVAudioPCMBuffer,
        to outputStream: OutputStream
    ) throws {
        guard let sourceChannelData = sourceAudioBuffer.floatChannelData else {
            throw SwiftLameError.couldNotReadChannelDataFromPCMBuffer
        }
        let frameLength = sourceAudioBuffer.frameLength
        
        let outputBufferSize = headerSafetyNetByteCount + frameLength * lame.sourceChannelCount
        var outputBuffer = Data(count: Int(outputBufferSize))
        var encodeLength: Int = 0
        
        try outputBuffer.withUnsafeMutableBytes { (rawOutputBufferPointer: UnsafeMutableRawBufferPointer) in
            let boundBuffer = rawOutputBufferPointer.bindMemory(to: UInt8.self)
            guard let baseAddress = boundBuffer.baseAddress else {
                throw SwiftLameError.couldNotGetRawOutputBufferPointerBaseAddress
            }
            
            if frameLength == 0 {
                encodeLength = lame.encodeFlushNoGap(at: baseAddress)
            } else {
                encodeLength = lame.encodeBufferIEEEFloat(
                    data: sourceChannelData,
                    frameLength: frameLength,
                    baseAddress: baseAddress,
                    outputBufferSize: outputBufferSize
                )
            }
            
            outputStream.write(baseAddress, maxLength: encodeLength)
        }
    }
}
