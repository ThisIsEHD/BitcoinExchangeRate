//
//  Extension.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/02.
//

import Foundation

extension Encodable {
    func toJSONData() -> Data? {
        let jsonData = try? JSONEncoder().encode(self)
        return jsonData
    }
}

extension Data {
    func jsonDecode<T: Codable>(type: T.Type) -> T? {

        let jsonDecoder = JSONDecoder()
        let result: Codable?

        do {
            
            result = try jsonDecoder.decode(type, from: self)

            return result as? T
        } catch {

            print(error, "🔥🔥")

            return nil
        }
    }
}
