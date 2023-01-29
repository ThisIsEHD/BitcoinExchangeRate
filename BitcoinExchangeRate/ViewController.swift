//
//  ViewController.swift
//  BitcoinExchangeRate
//
//  Created by 신동훈 on 2023/01/29.
//

import UIKit
import Alamofire
import SnapKit

class ViewController: UIViewController {

    let priceLabel = UILabel(frame: .zero)
    let requestButton = UIButton(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        priceLabel.text = "0.0000"
        requestButton.setTitle("요청", for: .normal)
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
    }

    let apiKey = "9b4eceb3-9d7a-42d4-8167-15acc1807e0c"

    @objc private func buttonTapped() {
        getBitcoinPrice()
//        getBitcoinPrice { price in
//            priceLabel.text = price
//        }
    }
    
    private func getBitcoinPrice() {
        let url = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=BTC&convert=USD"
        
        let headers: HTTPHeaders = [
            "Accepts": "application/json",
            "X-CMC_Pro_API_Key": apiKey
        ]
        
        AF.request(url, headers: headers).validate().response { response in
            if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                print(json, "🥩")
            } else {
                print("실패")
            }
        }
    }
    
    func jsonDecode<T: Codable>(type: T.Type, data: Data) -> T? {

        let jsonDecoder = JSONDecoder()
        let result: Codable?

        do {

            result = try jsonDecoder.decode(type, from: data)

            return result as? T
        } catch {

            print(error)

            return nil
        }
    }
}
