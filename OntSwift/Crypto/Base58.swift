//
//  Base58.swift
//  OntSwift
//
//  Created by hsiaosiyuan on 2018/12/2.
//  Copyright © 2018 hsiaosiyuan. All rights reserved.
//

import Foundation
import Base58

/// ref https://github.com/pixelspark/base58

public func encryptSHA256(_ digest: UnsafeMutableRawPointer?, _ data: UnsafeRawPointer?, _ size: Int) -> Bool {
  if let data = data, let digest = digest {
    let d = Data(bytes: data, count: size)
    let dd = _Hash.sha256(d)

    dd.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
      memcpy(digest, UnsafeRawPointer(bytes), dd.count)
    }
    return true
  }
  return false
}

// Set the sha256 implementation at initialization time
let setSHA256Implementation: Void = {
  b58_sha256_impl = encryptSHA256
}()

public extension Data {
  public func base58checkEncoded(version: UInt8) -> String {
    _ = setSHA256Implementation
    var enc = Data(repeating: 0, count: count * 3)

    let s = withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> String? in
      var size = enc.count
      let success = enc.withUnsafeMutableBytes { ptr -> Bool in
        return b58check_enc(ptr, &size, version, bytes, self.count)
      }

      if success {
        return String(data: enc.subdata(in: 0 ..< (size - 1)), encoding: .utf8)!
      } else {
        fatalError()
      }
    }

    return s!
  }

  public var base58encoded: String {
    var mult = 2
    while true {
      var enc = Data(repeating: 0, count: count * mult)

      let s = withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> String? in
        var size = enc.count
        let success = enc.withUnsafeMutableBytes { ptr -> Bool in
          return b58enc(ptr, &size, bytes, self.count)
        }

        if success {
          return String(data: enc.subdata(in: 0 ..< (size - 1)), encoding: .utf8)!
        } else {
          return nil
        }
      }

      if let s = s {
        return s
      }

      mult += 1
    }
  }

  public static func decodeChecked(base58: String, version: UInt8) -> Data? {
    _ = setSHA256Implementation
    let source = base58.data(using: .utf8)!

    var bin = [UInt8](repeating: 0, count: source.count)

    var size = bin.count
    let success = source.withUnsafeBytes { (sourceBytes: UnsafePointer<CChar>) -> Bool in
      if b58tobin(&bin, &size, sourceBytes, source.count) {
        bin = Array(bin[(bin.count - size) ..< bin.count])
        return b58check(bin, size, sourceBytes, source.count) == Int32(version)
      }
      return false
    }

    if success {
      return Data(bytes: bin[1 ..< (bin.count - 4)])
    }
    return nil
  }

  public static func decode(base58: String) -> Data? {
    let source = base58.data(using: .utf8)!

    var bin = [UInt8](repeating: 0, count: source.count)

    var size = bin.count
    let success = source.withUnsafeBytes { (sourceBytes: UnsafePointer<CChar>) -> Bool in
      if b58tobin(&bin, &size, sourceBytes, source.count) {
        return true
      }
      return false
    }

    if success {
      return Data(bytes: bin[(bin.count - size) ..< bin.count])
    }
    return nil
  }
}
