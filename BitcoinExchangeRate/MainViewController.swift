//
//  ViewController.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/01/29.
//

import UIKit
import Alamofire
import SnapKit

class MainViewModel: WebSocketRequestDataSource {
    var allCoinLists: [String]? {
        didSet {
//            userdefault의 특정티커 정보 소환하여 tickers에 대입
        }
    }
    var tickers: Observable<[String]>?
    var error: NetworkError?
    
    func getReqeust() -> String {
        guard let tickers = tickers?.value, !tickers.isEmpty else { return "" }
        
        let arguments = tickers.map { ticker in Argument(instType: "SP", channel: "ticker", instID: ticker + "USDT") }
        let webSocketRequest = WebSocketRequest(op: "subscribe", args: arguments)
        
        guard let jsonData = webSocketRequest.toJSONData(),
              let strWebSocketRequest = String(data: jsonData, encoding: .utf8) else {
            return ""
        }

        return strWebSocketRequest
    }
    
    func getAllCoinsList() {
        let getAllCoinsListAPI = "https://api.bitget.com/api/spot/v1/public/currencies"
        
        AF.request(getAllCoinsListAPI).validate().response { response in
            guard let httpResponse = response.response,
                  let data = response.data,
                  httpResponse.statusCode == 200 else { self.error = .httpError; return }
            
            let jsonDataDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let coinsDataDictionary = jsonDataDictionary?["data"] as? [[String: Any]] else { return }
            
            var tickers = [String]()
            for singleCoinDataDictionary in coinsDataDictionary {
                if let coinName = singleCoinDataDictionary["coinName"] as? String {
                    tickers.append(coinName)
                }
            }
            
            tickers = coinsDataDictionary.map { $0["coinName"] as? String }.compactMap {$0}
        }
    }
}


class MainViewController: UIViewController {
    
    var socket: WebSocket?
    var viewModel: WebSocketRequestDataSource?
    
    let priceLabel = UILabel(frame: .zero)
    let requestButton = UIButton(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(["BTC", "ETH"], forKey: Constant.myFavoriteCoinsTickers)
        let myFavoriteCoinsTickers = UserDefaults.standard.object(forKey: Constant.myFavoriteCoinsTickers) as? [String] ?? []
        
        viewModel = MainViewModel(tickers: myFavoriteCoinsTickers)
        
        guard let viewModel = viewModel as? MainViewModel else { return }
        
        socket = Socket(url: URL(string: Constant.bitgetWebSocketURL)!, webSocketTaskProviderType: URLSession.self)
        socket?.delegate = self
        
        if !myFavoriteCoinsTickers.isEmpty {
            socket?.connect(with: viewModel.getWebSocketReqeust())
        }
        
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
        
        viewModel.getAllCoinsList()
    }

    @objc private func buttonTapped() {
    }
    
    private func setUpBinding() {
        guard let viewModel = viewModel as? MainViewModel else { return }
        viewModel.needsUpdate?.bind({ needsUpdate in
            self.socket?.connect(with: viewModel.getWebSocketReqeust())
        })
    }
}

extension MainViewController: WebSocketEventsDelegate {
    func handleError(_ error: NetworkError) {
        let alert = SimpleAlert(message: "네트워크 에러")
        present(alert, animated: true)
    }
}

class Socket: NSObject, WebSocket {
    var task: WebSocketTask?
    var delegate: WebSocketEventsDelegate?

    required init<T: WebSocketTaskProviderInUrlSession>(url: URL, webSocketTaskProviderType _: T.Type) {
        super.init()
        
        let urlSession = T(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        task = urlSession.createWebSocketTask(with: url)
    }

    func sendPing() {
        task?.sendPing(pongReceiveHandler: { error in
            guard let _ = error else { return }
            self.delegate?.handleError(.webSocketError)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
               self.sendPing()
           }
        })
    }
    
    func send(request: String) {
        task?.send(.string(request), completionHandler: { error in
            guard let _ = error else { return }
            self.delegate?.handleError(.webSocketError)
        })
    }
    
    func receive() {
        task?.receive(completionHandler: { result in

            switch result {
            case .success(let message):
                switch message {
                case .data:
                    self.delegate?.handleError(.webSocketError)

                case .string(let message):
                    print(message)
                    let messageData = message.data(using: .utf8)
                    if let webSocketResponse = messageData?.jsonDecode(type: WebSocketResponse.self) {
                        
                        guard let coinData = webSocketResponse.marketData.first else { return }
                        
                        print("last price:", webSocketResponse.marketData.first!.lastPrice)
                        
                        let ticker = String(coinData.tickerUSDT.dropLast(4))
                        
                        self.delegate?.viewModel?.handleCoinsPriceData(ticker: ticker, price: coinData.lastPrice)
                    }
                @unknown default:
                    self.delegate?.handleError(.webSocketError)
                }
            case .failure:
                self.delegate?.handleError(.webSocketError)
            }
            self.receive()
        })
    }
    
    func connect(with request: String) {
        task?.resume()
        sendPing()
        send(request: request)
        receive()
    }

    func disconnect() {
        task?.cancel()
    }
}
