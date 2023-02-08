//
//  BitcoinExchangeRateTests.swift
//  BitcoinExchangeRateTests
//
//  Created by 신동훈 on 2023/02/03.
//

import XCTest
@testable import BitcoinExchangeRate

final class BitcoinExchangeRateTests: XCTestCase {
    
    var socket: WebSocket!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = URL(string: "wss://demo.piesocket.com/v3/channel_123?api_key=VCXCEuvhGcBDP7XhiJJUDvR1e1D3eiVjgZ9VRiaV&notify_self")!
        socket = MockSocket(url: url, webSocketTaskProviderType: URLSession.self, dataSource: MockSocketRequestDataSource())
    }

    override func tearDownWithError() throws {
        socket.disconnect()
        socket = nil
        try super.tearDownWithError()
    }
    
    func testWebSocketWhenVerifiedWebscoketTesterURLInserted() throws {
//        let promise = expectation(description: "socket connected")
//        (socket as? MockSocket)?.testFulfilled = { promise.fulfill() }
//        socket.connect()
//        wait(for: [promise], timeout: 2)
//        XCTAssertNil(socket.delegate?.error)
    }
    
    func testWebSocketWithBitgetWhenProperTickersInsertedIntoDatasource() {
        let promise = expectation(description: "socket connected")
        let bitgetURL = URL(string: "wss://ws.bitget.com/mix/v1/stream")!
        let dataSource = MarketDataSocketRequestDataSource()
        
        dataSource.tickers = ["BTC"]
        
        socket = MockSocket(url: bitgetURL, webSocketTaskProviderType: URLSession.self, dataSource: dataSource)
        (socket as? MockSocket)?.testFulfilled = { promise.fulfill() }
        socket.connect()
        
        wait(for: [promise], timeout: 5)
        XCTAssertNil(socket.delegate?.error)
    }
}



class MockSocket: NSObject, WebSocket {
    var task: WebSocketTask?
    var delegate: WebSocketEventsDelegate?
    var dataSource: WebSocketRequestDataSource?
    
    required init<T>(url: URL, webSocketTaskProviderType _: T.Type, dataSource: WebSocketRequestDataSource?) where T : WebSocketTaskProviderInUrlSession {
        super.init()
        
        let urlSession = T(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.delegate = MockSocketEventsDelegate()
        self.task = urlSession.createWebSocketTask(with: url)
        self.dataSource = dataSource
    }
    
    var testFulfilled: (() -> ()) = {}
    
    func connect() {
        task?.resume()
    }
    
    func disconnect() {
        task?.cancel()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        
        task?.sendPing { error in
            guard let _ = error else { return }
            self.delegate?.error = .invalidOP
        }
        task?.send(.string(dataSource?.getReqeust() ?? "DummyRequest")) { error in
            guard let _ = error else { return }
            self.delegate?.error = .invalidOP
        }
        task?.receive { result in
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let message):
                    print(message)
                    let messageData = message.data(using: .utf8)
                    
                    if let _ = messageData?.jsonDecode(type: WebSocketResponse.self) {
                        self.testFulfilled()
                    } else {
                        if let _ = messageData?.jsonDecode(type: WebSocketInitialResponse.self) {
                            self.testFulfilled()
                            
                        } else {
                            self.delegate?.error = .invalidOP
                            self.testFulfilled()
                        }
                    }
                case .data(let message):
                    print(message)
                    self.testFulfilled()
                @unknown default:
                    print("unkonwn message")
                    self.testFulfilled()
                }
            case .failure:
                self.delegate?.error = .invalidOP
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("closed")
    }
}

class MockSocketRequestDataSource: WebSocketRequestDataSource {
    var tickers: [String]?
    
    func getReqeust() -> String {
        "dummyRequest"
    }
}

class MockSocketEventsDelegate: WebSocketEventsDelegate {
    var error: WebSocketError?
    var isNeedUpdate: Bool?
    
    func handleError() {
        
    }
}
