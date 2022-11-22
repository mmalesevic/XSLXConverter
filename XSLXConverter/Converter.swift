//
//  Converter.swift
//  xslx to json
//
//  Created by Matej Malesevic on 21.11.22.
//

import Foundation
import CoreXLSX
import os.log

class Converter {
    
    enum Error: Swift.Error {
        case fileCannotBeFound(file: String)
        case contentCannotBeReferenced
        case empty
        case toManyColumns
    }
    static func convert(from url: URL?, tableHasHeaders: Bool = true) async throws -> [[String:Encodable]] {
        
        guard let url = url else {
            throw Error.fileCannotBeFound(file: url?.absoluteString ?? "")
        }
        
        let data = try Data(contentsOf: url)
        let file = try XLSXFile(data: data)
        guard let sharedStrings = try file.parseSharedStrings() else {
            throw Error.contentCannotBeReferenced
        }
        
        var jsonStructure = [[String:Codable]]()
        
        for path in try file.parseWorksheetPaths() {
            var jsonObject = [String: Codable]()
            let ws = try file.parseWorksheet(at: path)
            let rows = ws.data?.rows ?? []
            
            guard let firstRow = rows.first else {
                throw Error.empty
            }
            
            var headers = [String]()
            
            var i = 0
            for headerCell in firstRow.cells {
                if let header = headerCell.stringValue(sharedStrings) {
                    os_log("append header: %{public}@", log: .converter, type: .debug, header)
                    headers.append(header)
                } else if let header = headerCell.value {
                    headers.append(header)
                    os_log("append header: %{public}@", log: .converter, type: .debug, header)
                } else {
                    os_log("append header: undefined", log: .converter, type: .debug)
                    headers.append("undefined")
                }
                i += 1
                if i >= 256 {
                    throw Error.toManyColumns
                }
            }
            
            for dataRow in rows.dropFirst() {
                for header in headers {
                    if let colIndex = headers.firstIndex(of: header) {
                        
                        if dataRow.cells.count > colIndex  {
                            let cellContent: String = dataRow.cells[colIndex].stringValue(sharedStrings) ?? ""
                            
                            jsonObject[header] = cellContent
                            
                        }
                    }
                }
                os_log("parsing row: %{public}@", log: .converter, type: .debug, String(describing: rows.firstIndex(where: { $0.reference == dataRow.reference})))
                jsonStructure.append(jsonObject)
            }
        }
        return jsonStructure
    }
}

