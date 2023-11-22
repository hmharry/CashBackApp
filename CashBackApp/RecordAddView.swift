//
//  IndividualPaymentView.swift
//  CashBackApp
//
//  Created by Hei Man on 12/11/2023.
//

import SwiftUI
import CoreData

struct RecordAddView: View {
    let currentDate = Date()
    @State var pic: String
    @State var bank: String
    @State var name: String
    @State var cashback: Double
    @State var piclist: [String]
    @State var banklist: [String]
    @State var namelist: [String]
    @State var cashbacklist: [Double]
    @State var mode: Bool
    @State var cardView: Usercard?
    var spend:Double

    @State private var selectedCardIndex = 0
    
    var body: some View {
        NavigationView {
            List {
                Picker(selection: $selectedCardIndex, label: Text("Card")) {
                    let merged = itemintoggle(bl: banklist, nl: namelist)
                    ForEach(0..<merged.count, id: \.self) { index in
                        Text(merged[index])
                        Image(piclist[index])
                        VStack{
                            Text("Cashback:" )
                            Text("\(cashbacklist[index])")
                        }
                        
                        VStack{
                            Text("Amount:" )
                            
                            Text("\(spend)")
                        }
                        VStack{
                            Text("Cashback earned:" )
                            Text("\(cashbacklist[index]*spend)")
                        }
                        VStack{
                            Text("Cashback Expiry Date:" )
                            Text("\(getValueAfterXDays(X:30))")
                        }
                        
                        
                    }.navigationBarBackButtonHidden(true) // Hide the default back button
                }
                // Other list items
            }
        }
        .navigationTitle("Add Record")
    }
    
    func itemintoggle(bl: [String], nl: [String]) -> [String] {
        var itemintog: [String] = []
        for i in 0..<bl.count {
            itemintog.append(bl[i] + " " + nl[i])
        }
        return itemintog
    }
    func getValueAfterXDays(X: Int) -> String {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.day = X
        
        if let futureDate = calendar.date(byAdding: dateComponents, to: Date()) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd" // Customize the date format as per your needs
            let dateString = formatter.string(from: futureDate)
            return dateString
        } else {
            return "Invalid date"
        }
    }
}
