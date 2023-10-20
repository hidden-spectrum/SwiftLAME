//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import Foundation


public struct LameConfiguration {
    
    // MARK: Internal
    
    let bitrateMode: LameBitrateMode
    let quality: LameQuality
    let sampleRate: LameSampleRate
    
    // MARK: Lifecycle
    
    public init(sampleRate: LameSampleRate = .default, bitrateMode: LameBitrateMode, quality: LameQuality = .standard) {
        self.bitrateMode = bitrateMode
        self.quality = quality
        self.sampleRate = sampleRate
    }
}
