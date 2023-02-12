//
//  SearchCoinViewController.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/11.
//

import UIKit
import Alamofire

typealias DataSource = UITableViewDiffableDataSource<Section, Ticker>
typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Ticker>

final class SearchCoinViewController: UIViewController {
    internal var allCoinsList = [Ticker]() {
        didSet {
            setUpTableView()
        }
    }
    internal var error: NetworkError?
    
    private lazy var searchController: UISearchController = {
       
        let s = UISearchController()
        
        navigationItem.searchController = s
        navigationItem.searchController?.searchResultsUpdater = self
        navigationItem.hidesSearchBarWhenScrolling = false
        
        return s
    }()
    
    var dataSource: DataSource?
    
    private lazy var tableView: UITableView = {
        
        let t = UITableView(frame: .zero)
        
        t.register(TickerTableViewCell.self, forCellReuseIdentifier: TickerTableViewCell.identifier)
        
        return t
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .appColor(.mainBackground)
        
        getAllCoinsList { result in
            switch result {
            case .success(let coins):
                self.allCoinsList = coins
            case .failure(let error):
                self.error = error
            }
        }
    }
    
    private func getAllCoinsList(completion: @escaping (Result<[Ticker], NetworkError>) -> Void) {
        let getAllCoinsListAPI = Constant.gettingAllCoinsURL
        
        AF.request(getAllCoinsListAPI).validate().response { response in
            guard let httpResponse = response.response,
                  let data = response.data,
                  httpResponse.statusCode == 200 else { completion(.failure(.httpError)); return }
            
            let jsonDataDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let coinsDataDictionary = jsonDataDictionary?["data"] as? [[String: Any]] else { completion(.failure(.httpError)); return }
            
            var tickers = [String]()
            for singleCoinDataDictionary in coinsDataDictionary {
                if let coinName = singleCoinDataDictionary["coinName"] as? String {
                    tickers.append(coinName)
                }
            }
            
            tickers = coinsDataDictionary.map { $0["coinName"] as? String }.compactMap {$0}
            
            let uniqueTickers = tickers.map { ticker in Ticker(name: ticker) }
            
            completion(.success(uniqueTickers))
        }
    }
    
    func query(with filter: String?) {
        let filtered = self.allCoinsList.filter { $0.name.hasPrefix(filter ?? "") }

        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(filtered)
        self.dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func setUpTableView() {
        dataSource = DataSource(tableView: tableView) { (tableView, indexPath, ticker) -> TickerTableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TickerTableViewCell.identifier, for: indexPath) as? TickerTableViewCell else { return TickerTableViewCell() }
            
            cell.ticker = ticker.name
            
            return cell
        }
    }
}

extension SearchCoinViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text
        query(with: text)
    }
}
