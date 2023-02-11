//
//  AddNewCoinTableViewCell.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/02/11.
//

import UIKit

final class AddNewCoinTableViewCell: UITableViewCell {

    static let identifier = "AddNewCoinTableViewCell"
    
    let button = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        contentView.backgroundColor = .appColor(.mainBackground)
        
        button.setTitle("Add New Coin List", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.tintColor = .systemBlue

        let addCoinImage = UIImage(systemName: "plus.circle")
        button.setImage(addCoinImage, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.centerY.centerX.equalTo(contentView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buttonTapped() {
        
    }
}
