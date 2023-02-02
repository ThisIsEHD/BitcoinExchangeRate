//
//  WebSocket.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/02.
//

import Foundation

struct WebSocket {
    
    private let webSocket: URLSessionWebSocketTask
    private let session: URLSession
    private let websocketURL = URL(string: "wss://ws.bitget.com/mix/v1/stream")!
    
    internal func resumeWebSocket(delegate: URLSessionWebSocketDelegate) {
        webSocket.resume()
    }
    
    internal func cancelWebSocket() {
        webSocket.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))
    }
    
    init(delegate: URLSessionWebSocketDelegate) {
        self.session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue())
        self.webSocket = session.webSocketTask(with: websocketURL)
    }
    
    internal func sendPing() {
        webSocket.sendPing(pongReceiveHandler: { error in
            if let error = error {
                print("error:", error)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
               self.sendPing()
           }
        })
    }
    
    internal func recieve() {
        webSocket.receive(completionHandler: { result in
            
            switch result {
            case .success(let message):
                switch message {
                case .data:
                    print("Got Data")
                    
                case .string(let message):
                    
                    let jsonData  = message.toJSONData()
                    let responseResult = jsonData?.jsonDecode(type: ResponseResult.self)
                    
                @unknown default:
                    print("unknown default")
                }
            case .failure(let error):
                print("Receive error: \(error)")
            }
            
            self.recieve()
        })
    }
    
    internal func send(tickers: [String]) {
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            for ticker in tickers {
                let requestInString = "{\"op\":\"subscribe\",\"args\":[{\"channel\":\"ticker\",\"instId\":\"\(ticker)USDT\",\"instType\":\"SP\"}]}"
                self.webSocket.send(.string(requestInString), completionHandler: { error in
                    if let error = error {
                        print("Send error: \(error)")
                    }
                })
            }
        }
    }
}
