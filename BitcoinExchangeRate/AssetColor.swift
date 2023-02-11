//
//  AssetColor.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/11.
//

import UIKit

enum AssetColor: String {
    case mainBackground
}

extension UIColor {
    
    static func appColor(_ name: AssetColor) -> UIColor {
        switch name {
        case .mainBackground:
            return UIColor(named: AssetColor.mainBackground.rawValue)!
        }
    }
}
