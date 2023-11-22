//
//  CardClass.swift
//  CashBackApp
//
//  Created by Hei Man on 14/11/2023.
//

import Foundation
struct Merchant: Identifiable, Decodable{
    var id : Int
    var name: String
    var image: String
    var HSBC: [String]
    var HASE: [String]
    var BOCHK: [String]
    var CITI: [String]
    var CITIC: [String]
    var SCB: [String]
}
