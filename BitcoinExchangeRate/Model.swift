//
//  Model.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/02.
//

import Foundation

struct ResponseResult: Codable {
    let action: String
    let arg: Arg
    let data: [MarketData]
}

// MARK: - Arg
struct Arg: Codable {
    let instType, channel, instID: String

    enum CodingKeys: String, CodingKey {
        case instType, channel
        case instID = "instId"
    }
}

// MARK: - Datum
struct MarketData: Codable {
    let instID, last, open24H, high24H: String
    let low24H, bestBid, bestAsk, baseVolume: String
    let quoteVolume: String
    let ts, labeID: Int
    let openUTC, chgUTC, bidSz, askSz: String

    enum CodingKeys: String, CodingKey {
        case instID = "instId"
        case last
        case open24H = "open24h"
        case high24H = "high24h"
        case low24H = "low24h"
        case bestBid, bestAsk, baseVolume, quoteVolume, ts
        case labeID = "labeId"
        case openUTC = "openUtc"
        case chgUTC, bidSz, askSz
    }
}
