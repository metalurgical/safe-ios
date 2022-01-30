//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 01.01.22.
//

import Foundation

// MARK: - Sol.Address
extension Sol {
    // TODO: init with string
    public struct Address {
        public var storage: UInt160
        public init() { storage = 0 }
        public init(storage: UInt160) { self.storage = storage }
    }
}

extension Sol.Address: SolAbiEncodable {
    public func encode() -> Data {
        // address: as in the uint160 case
        let result = storage.encode()
        return result
    }

    public mutating func decode(from data: Data, offset: inout Int) throws {
        try self.storage.decode(from: data, offset: &offset)
    }

    public var canonicalName: String {
        "address"
    }
}

extension Sol.Address: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }
}

public extension Sol.Address {
    init?(hex: String) {
        var string = hex
        if string.hasPrefix("0x") {
            string.removeFirst(2)
        }
        guard let uint = Sol.UInt160(string, radix: 16) else {
            return nil
        }
        self.storage = uint
    }

    init(data: Data) throws {
        if data.isEmpty {
            storage = 0
        } else if data.count == 20 {
            let padded = Data(repeating: 0, count: 32 - 20)
            storage = try Sol.UInt160(padded)
        } else {
            storage = try Sol.UInt160(data)
        }

    }
}
