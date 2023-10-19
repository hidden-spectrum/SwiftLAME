
import AVFAudio
import LAME


enum LAMEEncoderError: Error {
    case couldNotCreateAudioPCMBuffer
    case couldNotCreateOutputStreamTo(url: URL)
}


public struct LAMEEncoder {
    public let sourceURL: URL
    
    public init(sourceURL: URL) {
        self.sourceURL = sourceURL
    }
    
    public func encode(to destinationURL: URL) throws {
        
        print(destinationURL.deletingLastPathComponent().path)
        
        // Open audio file
        let audioFile = try AVAudioFile(forReading: sourceURL)
        
        // Create a buffer
        let audioFormat = audioFile.processingFormat
        let frameCapacity: AVAudioFrameCount = 1024 * 8
        
        guard let sourceAudioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCapacity) else {
            throw LAMEEncoderError.couldNotCreateAudioPCMBuffer
        }
        
        let lame = LAME(
            for: audioFile,
            sourceChannelCount: sourceAudioBuffer.format.channelCount,
            bitrateMode: .constant(320),
            quality: .standard,
            sampleRate: .default
        )
        
        guard let outputStream = OutputStream(url: destinationURL, append: true) else {
            throw LAMEEncoderError.couldNotCreateOutputStreamTo(url: destinationURL)
        }
            
        outputStream.open()
        var position: AVAudioFramePosition = 0
        
        while position < audioFile.length {
            do {
                try audioFile.read(into: sourceAudioBuffer)
                try lame.encode(from: sourceAudioBuffer, to: outputStream)
            } catch {
                print(error)
            }
            
            position += AVAudioFramePosition(sourceAudioBuffer.frameLength)
        }
        
        outputStream.close()
    }
}
