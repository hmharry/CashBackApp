//
//  CardView.swift
//  CashBackApp
//
//  Created by Justin Chan on 12/11/2023.
//

import SwiftUI
import CoreData


struct PaymentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        entity: Usercard.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Usercard.bankname, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.cardname, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.docbexpire, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.cashbackLimit, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.basicCashback, ascending: true)
        ],
        animation: .default)

    private var items: FetchedResults<Usercard>
    
    @FetchRequest(
        entity: PurchaseHistory.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PurchaseHistory.bankname, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.cardname, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.cashbackamount, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.pricepurch, ascending: true),
        ],
        animation: .default)

    private var histories: FetchedResults<PurchaseHistory>
    
    @State var showAddPurchase = false
    @State var showPreviousPurchase = false
    @State var date = Date()
    @State var cbMode = false
    
    var body: some View {
        List {
            HStack {
                Text("\(DateToString(date: date, format: "MMMM YYYY")):")
                    .font(.subheadline)
                    .bold()
                Spacer()
                if cbMode {
                    Text("$\(String(Int(GetMonthAmount(month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY")))))")
                        .font(.subheadline)
                        .bold()
                    Text("$\(String(format: "%.2f", GetMonthAmount(month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY"))))")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                } else {
                    Text("$\(String(format: "%.2f", GetMonthAmount(month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY"))))")
                        .font(.subheadline)
                        .bold()
                }
            }
            ForEach(items) { item in
                NavigationLink {
                    CardRecordView(cardname: item.cardname!, bankname: item.bankname!, cardimg: item.cardimage!, month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY"), cbMode: cbMode)
                } label: {
                    HStack {
                        Image(item.cardimage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130)
                        Spacer()
                        VStack {
                            Text(item.bankname!)
                            Text(item.cardname!)
                            if cbMode {
                                VStack {
                                    Text("$\(String(Int(GetTotalAmount(bank: item.bankname!, card: item.cardname!, month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY")))))")
                                        .font(.title)
                                        .bold()
                                    Text("$\(String(format: "%.2f", GetTotalAmount(bank: item.bankname!, card: item.cardname!, month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY"))))")
                                        .font(.footnote)
                                        .foregroundStyle(.gray)
                                }
                                Text("Expiry: \(DateToString(date: item.docbexpire!, format: "dd/MM/YYYY"))")
                            } else {
                                Text("$\(String(format: "%.2f", GetTotalAmount(bank: item.bankname!, card: item.cardname!, month: DateToString(date: date, format: "MMMM"), year: DateToString(date: date, format: "YYYY"))))")
                                    .font(.title)
                                    .bold()
                                Text("Due: \(DateToString(date: item.dopayment!, format: "dd/MM/YYYY"))")
                            }
                        }
                    }
                    .frame(height: 110)
                }
            }
        }
        .toolbar {
            if cbMode == false {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showAddPurchase = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("New")
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showPreviousPurchase = true
                }) {
                    HStack {
                        Image(systemName: "clock")
                        Text("Previous")
                    }
                }
            }
        }
        
        .sheet(isPresented: $showAddPurchase, content: {
            NewSpendingView()
        })
        
        .sheet(isPresented: $showPreviousPurchase, content: {
            PerviousSpendingView(cbMode: cbMode)
        })
    }
    
    func DateToString(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    
    func GetTotalAmount(bank: String, card: String, month: String, year: String) -> Double {
        var total = 0.0
        
        for history in histories {
            if (history.bankname == bank) && (history.cardname == card) {
                if history.date != nil {
                    if (DateToString(date: history.date!, format: "MMMM") == month) && (DateToString(date: history.date!, format: "YYYY") == year) {
                        if cbMode {
                            total += history.cashbackamount
                        } else {
                            total += history.pricepurch
                        }
                    }
                }
            }
        }
        
        return total
    }
    
    func GetMonthAmount(month: String, year: String) -> Double {
        var amount = 0.0
        
        for card in items {
            amount += GetTotalAmount(bank: card.bankname!, card: card.cardname!, month: month, year: year)
        }
        
        return amount
    }
}
        
//#Preview {
//    PaymentView()
//}

