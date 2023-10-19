//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import Foundation


public enum SampleRate {
    case `default`
    case custom(Int32)
    
    var lameRepresentation: Int32 {
        switch self {
        case .default:
            0
        case .custom(let sampleRate):
            sampleRate
        }
    }
}
