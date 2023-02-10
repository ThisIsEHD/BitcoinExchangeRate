//
//  WebSocket.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/02.
//

import Foundation

enum NetworkError: Error {
    case webSocketError
    case httpError
}

protocol WebSocketTask {
    func resume()
    func cancel()
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)
    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
    func sendPing(pongReceiveHandler: @escaping @Sendable (Error?) -> Void)
}

extension URLSessionWebSocketTask: WebSocketTask {}

protocol WebSocketTaskProviderInUrlSession {
    init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue queue: OperationQueue?)
    func createWebSocketTask(with url: URL) -> WebSocketTask
}

extension URLSession: WebSocketTaskProviderInUrlSession {
    func createWebSocketTask(with url: URL) -> WebSocketTask {
        webSocketTask(with: url)
    }
}

protocol WebSocket: URLSessionWebSocketDelegate {
    var task: WebSocketTask? { get set }
    var delegate: WebSocketEventsDelegate? { get set }

    init<T: WebSocketTaskProviderInUrlSession>(url: URL, webSocketTaskProviderType _: T.Type)

    func connect(with request: String)
    func disconnect()
}

protocol WebSocketEventsDelegate {
    var viewModel: WebSocketRequestDataSource? { get set }
    
    func handleError(_ error: NetworkError)
}

protocol WebSocketRequestDataSource {
    var tickers: [String]? { get set }
    
    func getWebSocketReqeust() -> String
    func handleCoinsPriceData(ticker: String, price: String)
}

//struct WebSocket {
//
//    private let webSocket: URLSessionWebSocketTask
//    private let session: URLSession
//    private let websocketURL = URL(string: "wss://ws.bitget.com/mix/v1/stream")!
//
//    internal func resumeWebSocket() {
//        webSocket.resume()
//    }
//
//    internal func cancelWebSocket() {
//        webSocket.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))
//    }
//
//    init(delegate: URLSessionWebSocketDelegate) {
//        self.session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue())
//        self.webSocket = session.webSocketTask(with: websocketURL)
//    }
//
//    internal func sendPing() {
//        webSocket.sendPing(pongReceiveHandler: { error in
//            if let error = error {
//                print("error:", error)
//            }
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
//               self.sendPing()
//           }
//        })
//    }
//
//    internal func recieve(in viewModel: MainViewModel) {
//        webSocket.receive(completionHandler: { result in
//
//            switch result {
//            case .success(let message):
//                switch message {
//                case .data:
//                    print("Got Data")
//
//                case .string(let message):
//
//                    let messageData = message.data(using: .utf8)
//                    if let webSocketResponse = messageData?.jsonDecode(type: WebSocketResponse.self) {
//                        print("last price:", webSocketResponse.marketData.first!.last)
//                        viewModel.price.value = webSocketResponse.marketData.first?.last ?? "0"
//                    }
//                @unknown default:
//                    print("unknown default")
//                }
//            case .failure(let error):
//                print("Receive error: \(error)")
//            }
//            self.recieve(in: viewModel)
//        })
//    }
//
//    internal func send(tickers: [String]) {
//    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
//
//            let request = composeRequestString(tickers: tickers)
//
//            self.webSocket.send(.string(request), completionHandler: { error in
//                if let error = error {
//                    print("Send error: \(error)")
//                }
//            })
//        }
//    }
//}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
