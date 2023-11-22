//
//  AllCardModel.swift
//  CashBackApp
//
//  Created by Hei Man on 14/11/2023.
//

import Foundation
class CardModel:ObservableObject{
    @Published var allCards:[Card]=Array()
    init() {
        let pathString = Bundle.main.path(forResource: "data", ofType: "json")
        if let path = pathString{
            let url = URL(filePath: path)
                     print(url)
            do{
                let data = try Data(contentsOf: url)
                
                let decoder = JSONDecoder()

                do {
                    let cardData = try decoder.decode([Card].self, from: data)
                    self.allCards = cardData
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
