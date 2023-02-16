//
//  CoinDataTableViewCell.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/12.
//

import UIKit

final class CoinDataTableViewCell: UITableViewCell {
    
    static let identifier = "CoinDataTableViewCell"
    
    var coin = Observable(Coin(ticker: Ticker(value: "")))
    
    var ticker: String = ""
    var viewModel: WebSocketRequestDataSource? {
        didSet {
            print(ticker, "🇹🇳")
            setupbinding()
        }
    }
    var setupbinding = {}
    private let logoImageView = UIImageView(frame: .zero)
    private let tickerLabel = UILabel(frame: .zero)
    private let scaleLabel: UILabel = {
       
        let l = UILabel(frame: .zero)
        
        l.textColor = .label
        l.font = .systemFont(ofSize: 15)
        
        return l
    }()
    private let btcLabel: UILabel = {
       
        let l = UILabel(frame: .zero)
        
        l.text = "BTC"
        l.textColor = .systemGray
        l.font = .systemFont(ofSize: 11)
        
        return l
    }()
    private let greenOrRedView: UIView = {
        
        let v = UIView(frame: .zero)
        
        v.layer.cornerRadius = 4
        v.backgroundColor = .appColor(.plus)
        
        return v
    }()
    private let percentageLabel: UILabel = {
       
        let l = UILabel(frame: .zero)
        
        l.textColor = .label
        l.font = .boldSystemFont(ofSize: 16)
        
        return l
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .appColor(.mainBackground)
        
        selectionStyle = .default
        
        logoImageView.image = UIImage(named: "defaultCoinImage")!
        tickerLabel.text = "ETH"
        scaleLabel.text = "0.123456"
        percentageLabel.text = "+11.00%" //최대 4자리
        
        NotificationCenter.default.addObserver(self, selector: #selector(noti), name: Notification.Name("noti"), object: nil)
        setUpBinding()
        addSubviews()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func noti() {
        
        guard let coiny = viewModel?.altCoins[ticker] else { return }
        print("📣")
        print(coiny)
        self.coin.value = coiny
    }
    
    private func setUpBinding() {
//        coin.bitScale.bind({ bitscale in
//            self.scaleLabel.text = bitscale
//        })
//        coin.fluctuation.bind({ percentage in
//            self.percentageLabel.text = percentage
//        })
//        viewModel?.altCoins[ticker]?.bitScale?.bind({ bitscale in
//            self.scaleLabel.text = bitscale
//        })
//        viewModel?.altCoins[ticker]?.fluctuation?.bind({ percentage in
//            self.percentageLabel.text = percentage
//        })
        self.coin.bind { coin in
            DispatchQueue.main.async {
                print("🍓")
                self.percentageLabel.text = coin.fluctuation
                self.scaleLabel.text = coin.bitScale
            }
            
        }
    }
    
    private func addSubviews() {
        contentView.addSubview(logoImageView)
        contentView.addSubview(tickerLabel)
        contentView.addSubview(scaleLabel)
        contentView.addSubview(btcLabel)
        contentView.addSubview(greenOrRedView)
        greenOrRedView.addSubview(percentageLabel)
    }
    
    private func setConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(50)
            make.leading.equalTo(contentView.snp.leading).inset(25)
            make.top.bottom.equalTo(contentView).inset(10)
        }

        tickerLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoImageView.snp.trailing).offset(20)
            make.centerY.equalTo(contentView)
        }
        
        greenOrRedView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailing).inset(20)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        percentageLabel.snp.makeConstraints { make in
            make.centerY.centerX.equalTo(greenOrRedView)
        }
        
        btcLabel.snp.makeConstraints { make in
            make.trailing.equalTo(greenOrRedView.snp.leading).offset(-10)
            make.bottom.equalTo(greenOrRedView.snp.bottom).inset(5)
        }
        
        scaleLabel.snp.makeConstraints { make in
            make.trailing.equalTo(btcLabel.snp.leading).offset(-5)
            make.centerY.equalTo(contentView)
        }
    }
}
