//
//  Constant.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/09.
//

import Foundation

struct Constant {
    static let websocketTestURL = "wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self"
    static let bitgetWebSocketURL = "wss://ws.bitget.com/mix/v1/stream"
    static let tempLogoURL = "https://cryptoicons.org"
    static let gettingAllCoinsURL = "https://api.bitget.com/api/spot/v1/public/currencies"
    
    static let myFavoriteCoinsTickers = "myFavoriteCoinsTickers"
    static let OK = "확인"
}


enum Section: Int, CaseIterable {
    case main
}
