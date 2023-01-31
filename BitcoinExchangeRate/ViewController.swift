//
//  ViewController.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/01/29.
//

import UIKit
import Alamofire
import SnapKit

class ViewController: UIViewController {

    private var webSocket: URLSessionWebSocketTask?
    
    let priceLabel = UILabel(frame: .zero)
    let requestButton = UIButton(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        guard let url = URL(string: "wss://ws.bitget.com/mix/v1/stream") else { return }
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        priceLabel.text = "0.0000"
        requestButton.setTitle("요청", for: .normal)
        requestButton.backgroundColor = .blue
        
        view.addSubview(priceLabel)
        view.addSubview(requestButton)
        
        requestButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        priceLabel.snp.makeConstraints { make in
            make.center.equalTo(view)
        }
        requestButton.snp.makeConstraints { make in
            make.centerX.equalTo(priceLabel)
            make.top.equalTo(priceLabel).offset(30)
        }
    }

    @objc private func buttonTapped() {
        webSocket?.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))
    }
    
    func jsonDecode<T: Codable>(type: T.Type, data: Data) -> T? {

        let jsonDecoder = JSONDecoder()
        let result: Codable?

        do {

            result = try jsonDecoder.decode(type, from: data)

            return result as? T
        } catch {

            print(error)

            return nil
        }
    }
}

extension ViewController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("0 - Did connect to socket")
        ping()
        send()
        receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Did close connection with reason")
    }
    
    func ping() {
        webSocket?.sendPing(pongReceiveHandler: { error in
            if let error = error {
                print("error:", error)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                       self.ping()
           }
        })
    }
    
    func receive() {
        webSocket?.receive(completionHandler: { [weak self] result in
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got data: \(data)")
                case .string(let message):
                    print("Got string: \(message)")
                @unknown default:
                    print("unknown default")
                }
            case .failure(let error):
                print("Receive error: \(error)")
            }
            
            self?.receive()
        })
    }
    
    func send() {
        
           DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
               let data = "{\"op\":\"subscribe\",\"args\":[{\"channel\":\"ticker\",\"instId\":\"BTCUSDT\",\"instType\":\"SP\"}]}"
               self.webSocket?.send(.string(data), completionHandler: { error in
                   if let error = error {
                       print("Send error: \(error)")
                   }
               })
           }
       }
}
