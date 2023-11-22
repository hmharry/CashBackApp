//
//  PerviousSpendingView.swift
//  CashBackApp
//
//  Created by Justin Chan on 21/11/2023.
//

import SwiftUI
import CoreData

struct PerviousSpendingView: View {
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
    
    @State var date = Date()
    @State var month = Int(PaymentView().DateToString(date: Date(), format: "M"))! - 1
    @State var year = 3
    @State var cbMode = false
    
    var body: some View {
        NavigationView {
            List {
                HStack {
                    Picker("Year", selection: $year) {
                        ForEach(Int(PaymentView().DateToString(date: Date(), format: "YYYY"))! - 3 ..< Int(PaymentView().DateToString(date: Date(), format: "YYYY"))! + 1) {
                            Text(String($0))
                        }
                    }
                    .onChange(of: year, {
                        UpdateRecordDate()
                    })
                    .frame(width: 120)
                    Picker("Month", selection: $month) {
                        ForEach(0 ..< 12) {
                            Text(Calendar.current.monthSymbols[$0])
                        }
                    }
                    .onChange(of: month, {
                        UpdateRecordDate()
                    })
                }
                
                Spacer()
                
                HStack {
                    Text("\(PaymentView().DateToString(date: date, format: "MMMM YYYY")):")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    if cbMode {
                        Text("$\(String(Int(GetMonthAmount(month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY")))))")
                            .font(.subheadline)
                            .bold()
                        Text("$\(String(format: "%.2f", GetMonthAmount(month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY"))))")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    } else {
                        Text("$\(String(format: "%.2f", GetMonthAmount(month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY"))))")
                            .font(.subheadline)
                            .bold()
                    }
                }
                ForEach(items) { item in
                    NavigationLink {
                        CardRecordView(cardname: item.cardname!, bankname: item.bankname!, cardimg: item.cardimage!, month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY"), cbMode: cbMode)
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
                                    HStack {
                                        Text("$\(String(Int(GetTotalAmount(bank: item.bankname!, card: item.cardname!, month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY")))))")
                                            .font(.title)
                                            .bold()
                                        Text("$\(String(format: "%.2f", GetTotalAmount(bank: item.bankname!, card: item.cardname!, month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY"))))")
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                    }
                                    Text("Expiry: \(PaymentView().DateToString(date: item.docbexpire!, format: "dd/MM/YYYY"))")
                                } else {
                                    Text("$\(String(format: "%.2f", GetTotalAmount(bank: item.bankname!, card: item.cardname!, month: PaymentView().DateToString(date: date, format: "MMMM"), year: PaymentView().DateToString(date: date, format: "YYYY"))))")
                                        .font(.title)
                                        .bold()
                                    Text("Due: \(PaymentView().DateToString(date: item.dopayment!, format: "dd/MM/YYYY"))")
                                }
                            }
                        }
                        .frame(height: 100)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func GetTotalAmount(bank: String, card: String, month: String, year: String) -> Double {
        var total = 0.0
        
        for history in histories {
            if (history.bankname == bank) && (history.cardname == card) {
                if history.date != nil {
                    if (PaymentView().DateToString(date: history.date!, format: "MMMM") == month) && (PaymentView().DateToString(date: history.date!, format: "YYYY") == year) {
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
    
    func UpdateRecordDate() {
        let monthStr = String(month + 1)
        let yearStr = String(Int(PaymentView().DateToString(date: Date(), format: "YYYY"))! - (3 - year))
        let dateStr = "01/\(monthStr)/\(yearStr)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        date = dateFormatter.date(from: dateStr)!
    }
}

