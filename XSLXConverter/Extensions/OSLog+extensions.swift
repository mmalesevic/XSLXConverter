//
//  OSLog+extensions.swift
//  xslx to json
//
//  Created by Matej Malesevic on 21.11.22.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "ch.malesevic.xslx_to_json"
    
    static var converter = OSLog(subsystem: subsystem, category: "converter")
}
