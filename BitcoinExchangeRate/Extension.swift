//
//  Extension.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/02.
//

import UIKit

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

class SimpleAlert: UIAlertController {
    // MARK: - Initialization
    convenience init(message: String?) {
        self.init(title: nil, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: Constant.OK, style: .default, handler: nil)
        
        self.addAction(okAction)
    }
    
    convenience init(buttonTitle: String?, message: String?, completion: ((UIAlertAction) -> Void)?) {
        self.init(title: nil, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: buttonTitle, style: .default, handler: completion)
        
        self.addAction(okAction)
    }
}
