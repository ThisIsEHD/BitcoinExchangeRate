//
//  WebSocketTests.swift
//  WebSocketTests
//
//  Created by 신동훈 on 2023/02/03.
//

import XCTest
@testable import BitcoinExchangeRate

final class WebSocketTests: XCTestCase {
    
    var socket: WebSocket!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = URL(string: Constant.websocketTestURL)!
        socket = MockSocket(url: url, webSocketTaskProviderType: URLSession.self)
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
        let bitgetURL = URL(string: Constant.bitgetWebSocketURL)!
        
        socket = MockSocket(url: bitgetURL, webSocketTaskProviderType: URLSession.self)
        (socket as? MockSocket)?.testFulfilled = { promise.fulfill() }
        socket.connect()
        
        wait(for: [promise], timeout: 5)
        XCTAssertNil(socket.delegate?.error)
    }
}



class MockSocket: NSObject, WebSocket {
    var task: WebSocketTask?
    var delegate: WebSocketEventsDelegate?
    
    required init<T>(url: URL, webSocketTaskProviderType _: T.Type) where T : WebSocketTaskProviderInUrlSession {
        super.init()
        
        let urlSession = T(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.delegate = MockSocketEventsDelegate()
        self.task = urlSession.createWebSocketTask(with: url)
    }
    
    var testFulfilled: (() -> ()) = {}
    
    func connect() {
        task?.resume()
    }
    
    func disconnect() {
        task?.cancel()
    }
    
    func getBTCRequest() -> String {
        let tickers = ["BTC"]
        
        let arguments = tickers.map { ticker in Argument(instType: "SP", channel: "ticker", instID: ticker + "USDT") }
        let webSocketRequest = WebSocketRequest(op: "subscribe", args: arguments)
        
        guard let jsonData = webSocketRequest.toJSONData(),
              let strWebSocketRequest = String(data: jsonData, encoding: .utf8) else {
            return ""
        }
        print(strWebSocketRequest, "🥩")
        return strWebSocketRequest
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        
        task?.sendPing { error in
            guard let _ = error else { return }
            self.delegate?.error = .webSocketError
        }
        task?.send(.string(getBTCRequest())) { error in
            guard let _ = error else { return }
            self.delegate?.error = .webSocketError
        }
        task?.receive { result in
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let message):
                    print(message)
                    let messageData = message.data(using: .utf8)
                    
                    if let _ = messageData?.jsonDecode(type: WebSocketResponse.self) {
//                        레이블에 이 데이터 보여주기
                    } else {
                        if let _ = messageData?.jsonDecode(type: WebSocketInitialResponse.self) {
                            
                        } else {
                            self.delegate?.error = .webSocketError
                        }
                    }
                    self.testFulfilled()
                case .data(let message):
                    print(message)
                    self.testFulfilled()
                @unknown default:
                    print("unkonwn message")
                    self.testFulfilled()
                }
            case .failure:
                self.delegate?.error = .webSocketError
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("closed")
    }
}

class MockSocketEventsDelegate: WebSocketEventsDelegate {
    var error: NetworkError?
    var isNeedUpdate: Bool?
    
    func handleError() {
        
    }
}
