//
//  BitcoinExchangeRateTests.swift
//  BitcoinExchangeRateTests
//
//  Created by 신동훈 on 2023/02/03.
//

import XCTest
@testable import BitcoinExchangeRate

final class BitcoinExchangeRateTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
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
    
    func connect() {
        task?.resume()
    }
    
    func disconnect() {
        task?.cancel()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        task?.sendPing { error in
            
        }
        task?.send(.string(dataSource?.getReqeust() ?? "DummyRequest")) { error in
            guard let error = error else { return }
            print(error)
        }
        task?.receive { result in
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let message):
                    print(message)
                case .data(let message):
                    print(message)
                @unknown default:
                    print("unkonwn message")
                }
            case .failure(let error):
                print(error)
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
