//
//  ViewController.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/01/29.
//

import UIKit
import Alamofire
import SnapKit

class MainViewModel {
    var selectedTickers: Observable<[String]> = Observable(["BTC"])
    var price: Observable<String>
    
    init(price: Observable<String>) {
        self.price = price
    }
}

class MainViewController: UIViewController {

    private lazy var webSocket = WebSocket(delegate: self)
    
    private var viewModel = MainViewModel(price: Observable(""))
    
    let priceLabel = UILabel(frame: .zero)
    let requestButton = UIButton(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webSocket.resumeWebSocket(delegate: self)
        
        priceLabel.text = "0.0000"
        requestButton.setTitle("중단", for: .normal)
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
        
        setUpBinding()
    }

    @objc private func buttonTapped() {
//        webSocket?.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))
    }
    
    private func setUpBinding() {
        viewModel.price.bind { price in
            print(#function)
            DispatchQueue.main.async {
                self.priceLabel.text = price
            }
        }
    }
}

extension MainViewController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("0 - Did connect to socket")
        webSocket.sendPing()
        webSocket.send(tickers: ["BTC"])
        webSocket.recieve(in: viewModel)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Did close connection with reason")
    }
}
