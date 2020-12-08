//
//  Publisher+UnwrapDecoding.swift
//  
//
//  Created by Max Kuznetsov on 08.12.2020.
//

import Foundation
import Combine

public extension Publisher {
    func decodeUnwrap<Item: Decodable>(type: Item.Type) -> Publishers.Map<Publishers.Decode<Self, UnwrapContainer<Item>, JSONDecoder>, Item> {
        self.decode(type: type, unwrapBy: "")
    }
    
    func decode<Item: Decodable>(
        type: Item.Type,
        unwrapBy key: String
    ) -> Publishers.Map<Publishers.Decode<Self, UnwrapContainer<Item>, JSONDecoder>, Item> {
        let decoder = JSONDecoder()
        if let codingKey = CodingUserInfoKey(rawValue: kUnwrapKey), !key.isEmpty {
            decoder.userInfo[codingKey] = key
        }
        
        return self.decode(type: type, decoder: decoder, unwrapBy: key)
    }
    
    func decode<Item: Decodable, Coder: TopLevelDecoder>(
        type: Item.Type,
        decoder: Coder,
        unwrapBy key: String
    ) -> Publishers.Map<Publishers.Decode<Self, UnwrapContainer<Item>, Coder>, Item> where Self.Output == Coder.Input {
        Publishers.Map(
            upstream: self.decode(type: UnwrapContainer<Item>.self, decoder: decoder),
            transform: { $0.value }
        )
    }
}

public let kUnwrapKey = "unwrap_key"

public struct UnwrapContainer<Value: Decodable>: Decodable {
    let value: Value
    
    private struct DynamicCodingKeys: CodingKey {
        
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        init?(intValue: Int) {
            return nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        let keys = container.allKeys
        
        if let codingKey = CodingUserInfoKey(rawValue: kUnwrapKey),
           let wrapKey = decoder.userInfo[codingKey] as? String,
           let decodeKey = DynamicCodingKeys(stringValue: wrapKey)
        {
            value = try container.decode(decodeKey)
        } else {
            value = try container.decode(keys.first!)
        }
    }
}
