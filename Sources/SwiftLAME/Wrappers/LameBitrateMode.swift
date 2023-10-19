//
//  Copyright © 2023 Hidden Spectrum, LLC. All rights reserved.
//

import Foundation
import LAME
import os.log


public enum LameBitrateMode {
    case variable(LameVbrMode)
    case constant(Int32)
    
    func configure(on lame: lame_t?) {
        switch self {
        case .constant(let bitrate):
            lame_set_VBR(lame, LameVbrMode.off.lameRepresentation)
            lame_set_brate(lame, bitrate)
        case .variable(let vbrMode):
            lame_set_VBR(lame, vbrMode.lameRepresentation)
        }
    }
}


public enum LameVbrMode: UInt32 {
    case off = 0
    case rh = 2
    case average = 3
    case modernRH = 4
    
    public static let `default`: Self = .modernRH
    
    var lameRepresentation: vbr_mode {
        vbr_mode(rawValue)
    }
}
