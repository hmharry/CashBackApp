//
//  CardClass.swift
//  CashBackApp
//
//  Created by Hei Man on 14/11/2023.
//

import Foundation
struct Card: Identifiable, Decodable{
    var id : String
    var bank: String
    var card: String
    var cardImage: String
    var basicCashback: Double
    var cardCashback: [String : Double]?
    var cashbackLimit: Double?
    var LimitPeriod : Int?
    var promo : String
//    init(from decoder: Decoder) throws {
//        var container = try decoder.container(keyedBy: CodingKeys.self)
//
//        // Decode other properties
//        card = try container.decode(String.self, forKey: .card)
//
//        // Assign a UUID
//        id = UUID()
//    }
    
    func HSBC(){
        
    }
    func HASE(){
        
    }
    func CITIC(){
        
    }
    func Citi(){
        
    }
    
}
