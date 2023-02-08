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
    
    func testSocketEvents() async throws {
        let promise = expectation(description: "socket connected")
        (socket as? MockSocket)?.testFulfilled = { promise.fulfill() }
        socket.connect()
        wait(for: [promise], timeout: 2)
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
            self.delegate?.error = error
        }
        task?.send(.string(dataSource?.getReqeust() ?? "DummyRequest")) { error in
            guard let error = error else { return }
            self.delegate?.error = error
        }
        task?.receive { result in
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let message):
                    print(message)
                    self.testFulfilled()
                case .data(let message):
                    print(message)
                    self.testFulfilled()
                @unknown default:
                    print("unkonwn message")
                    self.testFulfilled()
                }
            case .failure(let error):
                self.delegate?.error = error
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("closed")
    }
}

class MockSocketRequestDataSource: WebSocketRequestDataSource {
    var tickers: [String] = []
    
    func getReqeust() -> String {
        "dummyRequest"
    }
}

class MockSocketEventsDelegate: WebSocketEventsDelegate {
    var error: Error?
    var isNeedUpdate: Bool?
    
    func handleError() {
        
    }
}
