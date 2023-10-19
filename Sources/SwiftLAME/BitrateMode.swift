//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import Foundation
import LAME
import os.log


public enum BitrateMode {
    case variable(VBRMode)
    case constant(Int32)
    
    func configure(on lame: lame_t?) {
        switch self {
        case .constant(let bitrate):
            lame_set_VBR(lame, VBRMode.off.lameRepresentation)
            lame_set_brate(lame, bitrate)
        case .variable(let vbrMode):
            lame_set_VBR(lame, vbrMode.lameRepresentation)
        }
    }
}


public enum VBRMode: UInt32 {
    case off = 0
    case rh = 2
    case average = 3
    case modernRH = 4
    
    static let `default` = VBRMode.modernRH
    
    var lameRepresentation: vbr_mode {
        vbr_mode(rawValue)
    }
}
