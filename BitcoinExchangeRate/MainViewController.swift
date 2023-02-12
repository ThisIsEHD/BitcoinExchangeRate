//
//  ViewController.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/01/29.
//

import UIKit
import Alamofire
import SnapKit

final class MainViewModel: WebSocketRequestDataSource {
    var tickers: [String]? {
        didSet {
            tickers?.forEach({ ticker in
                if coinsPrice.value[ticker] == nil {
                    coinsPrice.value[ticker] = "0"
                }
            })
        }
    }
    var coinsPrice: Observable<[String : String]> = Observable([:])
    
    var error: NetworkError?
    var needsUpdate: Observable<Bool>?
    
    init(tickers: [String]?, error: NetworkError? = nil) {
        self.tickers = tickers
        self.error = error
    }
    
    func handleCoinsPriceData(ticker: String, price: String) {
        coinsPrice.value[ticker] = price
    }
    
    func getWebSocketReqeust() -> String {
        guard let tickers = tickers, !tickers.isEmpty else { return "" }
        
        let arguments = tickers.map { ticker in Argument(instType: "SP", channel: "ticker", instID: ticker + "USDT") }
        let webSocketRequest = WebSocketRequest(op: "subscribe", args: arguments)
        
        guard let jsonData = webSocketRequest.toJSONData(),
              let strWebSocketRequest = String(data: jsonData, encoding: .utf8) else {
            return ""
        }

        return strWebSocketRequest
    }
    
    func getAllCoinsList() {
        let getAllCoinsListAPI = Constant.gettingAllCoinsURL
        
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

final class MainViewController: UIViewController {
    
    private var socket: WebSocket?
    internal var viewModel: WebSocketRequestDataSource?
    
    private lazy var tableView: UITableView = {
       
        let t = UITableView(frame: .zero)
        
        t.register(CoinDataTableViewCell.self, forCellReuseIdentifier: CoinDataTableViewCell.identifier)
        t.dataSource = self
        t.delegate = self
        t.backgroundColor = .appColor(.mainBackground)
        
        return t
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .appColor(.mainBackground)
        
        initializeData()
        
        title = "BitScale"
        
        configureViews()
    }
    
    private func setUpBinding() {
        guard let viewModel = viewModel as? MainViewModel else { return }
//        viewModel.needsUpdate?.bind({ needsUpdate in
//            self.socket?.connect(with: viewModel.getWebSocketReqeust(), tickersCount: <#Int#>)
//        })
    }
    
    private func initializeData() {
        UserDefaults.standard.set(["BTC", "ETH", "BCH"], forKey: Constant.myFavoriteCoinsTickers)
        let myFavoriteCoinsTickers = UserDefaults.standard.object(forKey: Constant.myFavoriteCoinsTickers) as? [String] ?? []
        
        viewModel = MainViewModel(tickers: myFavoriteCoinsTickers)
        
        guard let viewModel = viewModel as? MainViewModel else { return }
        
        socket = Socket(url: URL(string: Constant.bitgetWebSocketURL)!, webSocketTaskProviderType: URLSession.self)
        socket?.delegate = self
        
        if !myFavoriteCoinsTickers.isEmpty {
            socket?.connect(with: viewModel.getWebSocketReqeust(), tickersCount: viewModel.tickers!.count)
        }
        
        setUpBinding()
    }
    
    private func configureViews() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appColor(.mainBackground)
        self.navigationItem.standardAppearance = appearance
        self.navigationItem.scrollEdgeAppearance = appearance
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalTo(view)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CoinDataTableViewCell.identifier, for: indexPath) as? CoinDataTableViewCell else {
            return CoinDataTableViewCell()
        }
        
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    
}

extension MainViewController: WebSocketEventsDelegate {
    func handleError(_ error: NetworkError) {
        let alert = SimpleAlert(message: "네트워크 에러")
        present(alert, animated: true)
    }
}

final class Socket: NSObject, WebSocket {
    var task: WebSocketTask?
    var delegate: WebSocketEventsDelegate?

    var receiveCount = 0
    var tickersCount = 0
    
    required init<T: WebSocketTaskProviderInUrlSession>(url: URL, webSocketTaskProviderType _: T.Type) {
        super.init()
        
        let urlSession = T(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        task = urlSession.createWebSocketTask(with: url)
    }

    func sendPing() {
        task?.sendPing(pongReceiveHandler: { error in
            guard let _ = error else { return }
            self.handleErrorInMainQueue()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 29) {
               self.sendPing()
           }
        })
    }
    
    func send(request: String) {
        task?.send(.string(request), completionHandler: { error in
            guard let _ = error else { return }
            self.handleErrorInMainQueue()
        })
    }
    
    func receive() {
        task?.receive(completionHandler: { result in

            switch result {
            case .success(let message):
                switch message {
                case .data:
                    self.handleErrorInMainQueue()

                case .string(let message):
                    let messageData = message.data(using: .utf8)
                    
                    if let webSocketResponse = messageData?.jsonDecode(type: WebSocketResponse.self) {
                        
                        guard let coinData = webSocketResponse.marketData.first else { return }
                        
                        let ticker = String(coinData.tickerUSDT.dropLast(4))
                        
                        self.delegate?.viewModel?.handleCoinsPriceData(ticker: ticker, price: coinData.lastPrice)
                        self.receiveCount += 1
                    }
                    
                @unknown default:
                    self.handleErrorInMainQueue()
                }
            case .failure:
                self.handleErrorInMainQueue()
            }
            
            if self.receiveCount >= self.tickersCount {
                DispatchQueue.global().asyncAfter(deadline: .now() + 5.1) {
                    self.receiveCount = 0
                    self.receive()
               }
                
            } else {
                DispatchQueue.global().async {
                    self.receive()
                }
            }
        })
    }
    
    func connect(with request: String, tickersCount: Int) {
        self.tickersCount = tickersCount
        task?.resume()
        sendPing()
        send(request: request)
        receive()
    }

    func disconnect() {
        task?.cancel()
    }
    
    func handleErrorInMainQueue() {
        DispatchQueue.main.async {
            self.delegate?.handleError(.webSocketError)
        }
    }
}
