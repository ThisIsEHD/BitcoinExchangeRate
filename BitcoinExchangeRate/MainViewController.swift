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
    var coins: [Coin]
    
    var error: NetworkError?
    var needsUpdate: Observable<Bool>?
        
    init(coins: [Coin]) {
        self.coins = coins
    }
    
    func handleCoinsPriceData(ticker: String, price: String) {
        var coin = coins.first { $0.ticker.value == ticker }
        coin?.price.value = price
    }
    
    func getWebSocketReqeust() -> String {
        guard !coins.isEmpty else { return "" }
        let arguments = coins.map { coin in Argument(instType: "SP", channel: "ticker", instID: coin.ticker.value + "USDT") }
        let webSocketRequest = WebSocketRequest(op: "subscribe", args: arguments)
        
        guard let jsonData = webSocketRequest.toJSONData(),
              let strWebSocketRequest = String(data: jsonData, encoding: .utf8) else {
            return ""
        }

        return strWebSocketRequest
    }
    
    func getCoinsImageURL(tickers: [Ticker]) {
        let coinsImageURL = Constant.gettingcoinsImageURL
        
        AF.request(coinsImageURL).validate().response { response in
            guard let httpResponse = response.response,
                  let data = response.data,
                  httpResponse.statusCode == 200 else { self.error = .httpError; return }
            
            let jsonDataDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let coinsDataDictionary = jsonDataDictionary?["Data"] as? [String: Any] else { return }
            
            self.coins = tickers.map({ ticker in
                if let singleCoinData = coinsDataDictionary[ticker.value] as? [String: Any] {
                    if let imageURL = singleCoinData["ImageUrl"] as? String {
                        return Coin(ticker: ticker, price: Observable(""), imageURL: Observable(imageURL))
                    } else {
                        return Coin(ticker: ticker, price: Observable(""), imageURL: Observable(""))
                    }
                } else {
                    return Coin(ticker: ticker, price: Observable(""), imageURL: Observable(""))
                }
            })
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
        UserDefaults.standard.set(["BTC", "ETH", "BCH", "LTC", "XRP", "TRX"], forKey: Constant.myFavoriteCoinsTickers)  //나중에 없애야
        let tickersList = UserDefaults.standard.object(forKey: Constant.myFavoriteCoinsTickers) as? [String] ?? []
        let myFavoriteCoins = tickersList.map { ticker in Coin(ticker: Ticker(value: ticker)) }
        
        viewModel = MainViewModel(coins: myFavoriteCoins)
        
        socket = Socket(url: URL(string: Constant.bitgetWebSocketURL)!, webSocketTaskProviderType: URLSession.self)
        socket?.delegate = self
        
        if !myFavoriteCoins.isEmpty {
            socket?.connect(with: viewModel!.getWebSocketReqeust(), tickersCount: viewModel!.coins.count)
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
    var receivingCount = 0
    func receive() {
        task?.receive(completionHandler: { result in
            self.receivingCount += 1
            print(self.receivingCount)
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
                DispatchQueue.global().asyncAfter(deadline: .now() + 15.1) {
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
