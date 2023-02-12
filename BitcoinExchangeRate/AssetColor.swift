//
//  AssetColor.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/11.
//

import UIKit

enum AssetColor: String {
    case mainBackground, plus, minus
}

extension UIColor {
    
    static func appColor(_ name: AssetColor) -> UIColor {
        switch name {
        case .mainBackground:
            return UIColor(named: AssetColor.mainBackground.rawValue)!
        case .plus:
            return UIColor(named: AssetColor.plus.rawValue)!
        case .minus:
            return UIColor(named: AssetColor.minus.rawValue)!
        }
    }
}
