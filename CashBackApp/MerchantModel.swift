//
//  AllCardModel.swift
//  CashBackApp
//
//  Created by Hei Man on 14/11/2023.
//

import Foundation
class MerchantModel:ObservableObject{
    @Published var allMerchants:[Merchant]=Array()
    init() {
        let pathString = Bundle.main.path(forResource: "merchant", ofType: "json")
        if let path = pathString{
            let url = URL(filePath: path)
                     print(url)
            do{
                let data = try Data(contentsOf: url)
                
                let decoder = JSONDecoder()

                do {
                    let merchantData = try decoder.decode([Merchant].self, from: data)
                    self.allMerchants = merchantData
                }
                catch{
                    print("ERRL")
                    print(error)
                }
            }
            catch{
                print(error)
            }
        }
//        allCards.forEach{ name in
//            print(name.bank)
//            print(name.card)
//        }
        
    }
    
}
