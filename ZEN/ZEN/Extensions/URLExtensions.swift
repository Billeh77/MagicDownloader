//
//  URLExtensions.swift
//  ZEN
//
//  Created by Emile Billeh on 24/02/2025.
//

import Foundation

extension URL {
    /// ✅ Reads an extended attribute from the file
    func extendedAttribute(forName name: String) throws -> Data {
        let path = self.path
        let data = try URL.getxattr(path, name) // ✅ Explicitly call the global function
        return data
    }
    
    /// ✅ Retrieves raw extended attribute data using the global `getxattr`
    private static func getxattr(_ path: String, _ name: String) throws -> Data {
        let length = Darwin.getxattr(path, name, nil, 0, 0, 0) // ✅ Use `Darwin.getxattr` explicitly
        guard length >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil) }
        
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { buffer in
            Darwin.getxattr(path, name, buffer.baseAddress, length, 0, 0) // ✅ Use `Darwin.getxattr`
        }
        guard result >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil) }
        
        return data
    }
}
