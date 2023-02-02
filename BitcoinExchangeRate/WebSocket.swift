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
    
    internal func recieve(in viewModel: MainViewModel) {
        webSocket.receive(completionHandler: { result in
            
            switch result {
            case .success(let message):
                switch message {
                case .data:
                    print("Got Data")
                    
                case .string(let message):
                    
                    let messageData = message.data(using: .utf8)
                    if let webSocketResponse = messageData?.jsonDecode(type: WebSocketResponse.self) {
                        print("last price:", webSocketResponse.marketData.first!.last)
                        viewModel.price.value = webSocketResponse.marketData.first?.last ?? "0"
                    }
                @unknown default:
                    print("unknown default")
                }
            case .failure(let error):
                print("Receive error: \(error)")
            }
            self.recieve(in: viewModel)
        })
    }
    
    internal func send(tickers: [String]) {
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            
            let request = composeRequestString(tickers: tickers)
            
            self.webSocket.send(.string(request), completionHandler: { error in
                if let error = error {
                    print("Send error: \(error)")
                }
            })
        }
    }
    
    private func composeRequestString(tickers: [String]) -> String {
        let arguments = tickers.map { ticker in Argument(instType: "SP", channel: "ticker", instID: ticker + "USDT") }
        let webSocketRequest = WebSocketRequest(op: "subscribe", args: arguments)
        guard let jsonData = webSocketRequest.toJSONData(),
              let strWebSocketRequest = String(data: jsonData, encoding: .utf8) else {
            return ""
        }
        
        return strWebSocketRequest
//        let anArgumentValue = "{\"channel\":\"ticker\",\"instId\":\"\(ticker)USDT\",\"instType\":\"SP\"}"
    }
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
