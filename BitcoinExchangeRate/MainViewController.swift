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
    
    let priceLabel = UILabel(frame: .zero)
    let requestButton = UIButton(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getAllCoinsList()
        
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
    }
    
    private func setUpBinding() {
        
    }
    
    private func getAllCoinsList() {
        
    }
    
    private func showAlert() {
        let alert = SimpleAlert(message: "네트워크 에러")
        present(alert, animated: true)
    }
}

extension MainViewController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("0 - Did connect to socket")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Did close connection with reason")
    }
}
