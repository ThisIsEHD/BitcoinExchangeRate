//
//  GetCoinListTest.swift
//  BitcoinExchangeRateTests
//
//  Created by 신동훈 on 2023/02/09.
//

import XCTest

final class GetCoinListTest: XCTestCase {

    var sut: URLSession!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = URLSession.shared
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
}
