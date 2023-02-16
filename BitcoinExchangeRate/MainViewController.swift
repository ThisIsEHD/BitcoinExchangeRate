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
    
//    var coins: [String]   //이거 tickers: [String] 으로 바꿔도 무관할 수도 있어서 나중에 고려해보자.
    var altCoins = [String: Coin]() 
//        didSet {
//            needsUpdate?.value = true
//        }
    
    var btc = Coin(ticker: Ticker(value: Constant.BTC))
    var altCoinTickerList: [String] = []
    
    var error: NetworkError?
    var needsUpdate: Observable<Bool>?
    
    var receiveCount = 0
    
    init() {
        UserDefaults.standard.set(["BCH", "ETC", "ETH"], forKey: Constant.myFavoriteCoinsTickers)
        altCoinTickerList = UserDefaults.standard.object(forKey: Constant.myFavoriteCoinsTickers) as? [String] ?? [String]()
        print(altCoinTickerList, "⭐️")
        altCoins = altCoinTickerList.reduce(into: [String: Coin]()) { dict, ticker in
            dict[ticker] = Coin(ticker: Ticker(value: ticker))
        }
        
        altCoins[Constant.BTC] = Coin(ticker: Ticker(value: Constant.BTC))
        
//        coins = altCoinTickerList
//        coins.append("BTC")
    }
    
    func getWebSocketReqeust() -> String {
        guard !altCoins.isEmpty else { return "" }
        
        var willSearchCoins = altCoinTickerList
        willSearchCoins.append("BTC")
        
        let arguments: [Argument] = willSearchCoins.map{ Argument(instType: "SP", channel: "ticker", instID: $0 + "USDT") }
        let webSocketRequest = WebSocketRequest(op: "subscribe", args: arguments)

        guard let jsonData = webSocketRequest.toJSONData(),
              let strWebSocketRequest = String(data: jsonData, encoding: .utf8) else {
            return ""
        }

        return strWebSocketRequest
    }
    
//    func getCoinsImageURL(tickers: [Ticker]) {
//        let coinsImageURL = Constant.gettingcoinsImageURL
//
//        AF.request(coinsImageURL).validate().response { response in
//            guard let httpResponse = response.response,
//                  let data = response.data,
//                  httpResponse.statusCode == 200 else { self.error = .httpError; return }
//
//            let jsonDataDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//
//            guard let coinsDataDictionary = jsonDataDictionary?["Data"] as? [String: Any] else { return }
//
//            self.coins = tickers.map({ ticker in
//                if let singleCoinData = coinsDataDictionary[ticker.value] as? [String: Any] {
//                    if let imageURL = singleCoinData["ImageUrl"] as? String {
//                        return Coin(ticker: ticker, price: Observable(""), imageURL: Observable(imageURL))
//                    } else {
//                        return Coin(ticker: ticker, price: Observable(""), imageURL: Observable(""))
//                    }
//                } else {
//                    return Coin(ticker: ticker, price: Observable(""), imageURL: Observable(""))
//                }
//            })
//        }
//    }
    var isInitial = true {
        didSet {
            needsUpdate?.value = true
        }
    }
    func receiveCoinData(_ data: ACoinMarketData) {
        receiveCount += 1
    
        let ticker = String(data.tickerUSDT.dropLast(4))
        let lastPrice = data.lastPrice
        let open24hPrice = data.open24H
        
        if ticker == Constant.BTC {
            btc.price = Double(lastPrice)
            btc.openPrice = Double(open24hPrice)
        } else {
            altCoins[ticker]?.price = Double(lastPrice)
            altCoins[ticker]?.openPrice = Double(open24hPrice)
        }
        
        let bitCount = 1
        
        if receiveCount == altCoinTickerList.count + bitCount {
        
            var tempAltCoins = [String: Coin]()
            
            self.altCoins.forEach { ticker, coin in
                
                guard let altPrice = coin.price,
                      let bitPrice = btc.price,
                      let altOpenPrice = coin.openPrice,
                      let bitOpenPrice = btc.openPrice else { return }

                let altCoinPerBit = altPrice / bitPrice
                let openTimeCoinPerBit = altOpenPrice / bitOpenPrice

                var altCoinIncludingBtcData = coin
                altCoinIncludingBtcData.bitScale = String(format: "%.6f", altCoinPerBit)
                altCoinIncludingBtcData.fluctuation = getFluctuationPercentage(open: openTimeCoinPerBit, now: altCoinPerBit)
                tempAltCoins[ticker] = altCoinIncludingBtcData
                
                print("\(ticker)-> 알트 가격:\(altCoinPerBit), 변동성: \(getFluctuationPercentage(open: openTimeCoinPerBit, now: altCoinPerBit))")
            }
            
            altCoins = tempAltCoins
            receiveCount = 0
            
            if isInitial {
                print("👎")
                isInitial = false
            }
            NotificationCenter.default.post(name: Notification.Name("noti"), object: nil)
        }
    }
    
    func getFluctuationPercentage(open: Double, now: Double) -> String {
        let difference = now - open
        let percentage = difference / open * 100

        if difference >= open * 10 {
            let totalPercentage = (now / open - 1) * 100
            return "\(String(format: "+%.0f", totalPercentage))%"
        } else if difference >= open * 2 {
            let totalPercentage = (now / open - 1) * 100
            return "\(String(format: "+%.1f", totalPercentage))%"
        } else if difference > 0 {
            return "\(String(format: "+%.2f", percentage))%"
        } else if difference <= -open * 2 {
            let totalPercentage = (now / open - 1) * 100
            return "\(String(format: "+%.1f", totalPercentage))%"
        } else if difference < 0 {
            return "\(String(format: "-%.2f", -percentage))%"
        } else {
            return "0.00%"
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
        
        viewModel = MainViewModel()
        setUpBinding()
        initializeWebSocket()
        
        title = "BitScale"
        
        configureViews()
    }
    
    private func setUpBinding() {
        (viewModel as? MainViewModel)?.needsUpdate?.bind({ needsUpdate in
            print(#function,"📣")
            if needsUpdate {
                self.tableView.reloadData()
            }
        })
    }
    
    private func initializeWebSocket() {
        socket = Socket(url: URL(string: Constant.bitgetWebSocketURL)!, webSocketTaskProviderType: URLSession.self)
        socket?.delegate = self
        
        guard let viewModel = viewModel, !viewModel.altCoins.isEmpty else { return }
        
        socket?.connect(with: viewModel.getWebSocketReqeust(), tickersCount: viewModel.altCoinTickerList.count + 1)
        
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
        guard let viewModel = viewModel else { return 0 }
        
//        let addNewCoinCellNumber = 1
        
//        return viewModel.altCoins.count + addNewCoinCellNumber
        print(viewModel.altCoins)
        return viewModel.altCoinTickerList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CoinDataTableViewCell.identifier, for: indexPath) as? CoinDataTableViewCell else {
            return CoinDataTableViewCell()
        }
        
        guard let viewModel = viewModel else { return UITableViewCell() }
        cell.ticker = viewModel.altCoinTickerList[indexPath.row]
        cell.viewModel = viewModel
//        cell.fetch = viewModel.fetchCoinData
        
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    
}














extension MainViewController: WebSocketEventsDelegate {
    
    func handle(_ data: ACoinMarketData) {
        (viewModel as? MainViewModel)?.receiveCoinData(data)
    }
    
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
                        
                        self.delegate?.handle(coinData)
                        self.receiveCount += 1
                    }
                    
                @unknown default:
                    self.handleErrorInMainQueue()
                }
            case .failure:
                self.handleErrorInMainQueue()
            }
            
            if self.receiveCount >= self.tickersCount {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
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
