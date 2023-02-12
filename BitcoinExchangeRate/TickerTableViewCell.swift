//
//  TickerTableViewCell.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/11.
//

import UIKit

class TickerTableViewCell: UITableViewCell {
    
    static let identifier = "TickerTableViewCell"
    
    internal var ticker: String? {
        didSet {
            label.text = ticker
        }
    }
    
    private let label = UILabel(frame: .zero)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .appColor(.mainBackground)
        
        selectionStyle = .default
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView.snp.leading).inset(44)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
