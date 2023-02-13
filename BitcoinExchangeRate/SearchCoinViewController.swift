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
            guard var snapShot = dataSource?.snapshot() else { return }
            
            snapShot.appendSections([.main])
            snapShot.appendItems(allCoinsList)
            dataSource?.apply(snapShot, animatingDifferences: true)
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
        t.dataSource = dataSource
        t.delegate = self
        t.backgroundColor = .appColor(.mainBackground)
        
        return t
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getAllCoinsList { result in
            switch result {
            case .success(let coins):
                self.allCoinsList = coins
            case .failure(let error):
                self.error = error
            }
        }
        
        view.backgroundColor = .appColor(.mainBackground)
        
        setUpTableView()
    }
    
    private func getAllCoinsList(completion: @escaping (Result<[Ticker], NetworkError>) -> Void) {
        let getAllCoinsListAPI = Constant.gettingAllCoinsURL
        
        AF.request(getAllCoinsListAPI).validate().response { response in
            guard let httpResponse = response.response,
                  let data = response.data,
                  httpResponse.statusCode == 200 else { completion(.failure(.httpError)); return }
            
            let jsonDataDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            guard let coinsDataDictionary = jsonDataDictionary?["data"] as? [[String: Any]] else { completion(.failure(.httpError)); return }
                        
            let tickers = coinsDataDictionary.map { $0["coinName"] as? String }.compactMap {$0}.map{ Ticker(value: $0)}
            
            completion(.success(tickers))
        }
    }
    
    func query(with filter: String?) {
        let filteredTickers = self.allCoinsList.filter { $0.value.hasPrefix(filter ?? "") }

        guard var snapShot = dataSource?.snapshot() else { return }
        
        if snapShot.numberOfSections == 0 {
            snapShot.appendSections([.main])
        }
        
        snapShot.appendItems(filteredTickers)
        dataSource?.apply(snapShot, animatingDifferences: true)
    }
    
    private func setUpTableView() {
        dataSource = DataSource(tableView: tableView) { (tableView, indexPath, ticker) -> TickerTableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TickerTableViewCell.identifier, for: indexPath) as? TickerTableViewCell else { return TickerTableViewCell() }
            
            cell.ticker = ticker.value
            
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

extension SearchCoinViewController: UITableViewDelegate {
    
}
