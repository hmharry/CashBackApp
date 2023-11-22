//
//  NewSpendingView.swift
//  CashBackApp
//
//  Created by Justin Chan on 20/11/2023.
//

import SwiftUI

struct NewSpendingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var cardModel: CardModel
    @EnvironmentObject var merchantModel: MerchantModel
    
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
    
    @State var cardIndex = 0
    @State var cbTypeIndex = 0
    @State var merchantIndex = 0
    @State var spendingAmount = 0.0
    @State var cbTypeItem = 0
    @State var amountStr = ""
    @State var amount = 0.0
    @State var purchaseDate = Date()
    
    var body: some View {
        if(items.isEmpty) {
            Text("Please add your own card(s) first before adding the purchace record.")
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40.0)
        } else {
            NavigationStack {
                Form {
                    Section("Card:") {
                        Picker("Select Card", selection: $cardIndex) {
                            let cardName = CardsInfoToArray().0
                            ForEach(0 ..< cardName.count) {
                                Text(cardName[$0]).tag($0)
                            }
                        }
                        Image(CardsInfoToArray().1[cardIndex])
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    Section("Purchasement:") {
                        DatePicker("Date", selection: $purchaseDate)
                        Picker("Merchant", selection: $merchantIndex) {
                            let mcName = MerchantToArray()
                            ForEach(0 ..< mcName.count) {
                                Text(mcName[$0]).tag($0)
                            }
                        }
                        Picker("Cashback Type", selection: $cbTypeIndex) {
                            let cbType = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).0
                            ForEach(0 ..< cbType.count) {
                                Text(cbType[$0]).tag($0)
                            }
                        }
                        .id(cardIndex)
                        
                        TextField("Type in amount: $", text: $amountStr)
                            .multilineTextAlignment(.center)
                            .font(.title)
                            .bold()
                            .keyboardType(.decimalPad)
                        
                        HStack {
                            Text("Cashback Earned:")
                            Spacer()
                            
                            let cbVal = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).1[cbTypeIndex] + CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).2
                            Text("$\(String(format: "%.2f", CbAmountCal()))")
                        }
                        
                        let cbLim = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).3
                        
                        if cbLim != nil {
                            HStack {
                                Text("Cashback Expiry Date:")
                                Spacer()
                                let cbExp = CardsInfoToArray().2[cardIndex].addingTimeInterval(Double(cbLim!) * 24 * 60 * 60)
                                let dateStr = PaymentView().DateToString(date: cbExp, format: "dd/MM/YYYY")
                                Text(dateStr)
                            }
                        }
                    }
                    
                    if let _ = Double(amountStr) {
                        Button(action: {
                            if let price = Double(amountStr) {
                                let record = PurchaseHistory(context: viewContext)
                                record.bankname = CardsInfoToArray().3[cardIndex]
                                record.cardname = CardsInfoToArray().4[cardIndex]
                                record.cashbackamount = CbAmountCal()
                                record.cashbackbasic = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).2
                                record.cashbackextra = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).1[cbTypeIndex]
                                record.cashbackpercent = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).1[cbTypeIndex] + CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).2
                                record.pricepurch = price
                                record.date = purchaseDate
                                record.id = UUID()
                                record.merchant = MerchantToArray()[merchantIndex]
                                
                                for item in items {
                                    if (item.bankname == CardsInfoToArray().3[cardIndex]) && (item.cardname == CardsInfoToArray().4[cardIndex]) {
                                        item.docbexpire = CardsInfoToArray().2[cardIndex].addingTimeInterval(Double(CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).3!) * 24 * 60 * 60)
                                    }
                                }
                                
                                do {
                                    try viewContext.save()
                                } catch {
                                    let nsError = error as NSError
                                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                }
                                
                                dismiss()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("Add Record")
                                Spacer()
                            }
                        }
                    } else {
                        Text("Please enter the amount in numbers to continue!")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.gray)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    func CardsInfoToArray() -> ([String], [String], [Date], [String], [String]) {
        var nameArray: [String] = []
        var imageArray: [String] = []
        var expiryArray: [Date] = []
        var bankArray: [String] = []
        var cardArray: [String] = []
        
        for item in items {
            nameArray.append("\(item.bankname!) \(item.cardname!)")
            imageArray.append(item.cardimage!)
            expiryArray.append(item.docbexpire!)
            bankArray.append(item.bankname!)
            cardArray.append(item.cardname!)
        }
        
        return (nameArray, imageArray, expiryArray, bankArray, cardArray)
    }
    
    func CbTypeToArray(card: String) -> ([String], [Double], Double, Int?, Double?) {
        var cashbackArray: [String] = []
        var cbValueArray: [Double] = []
        var basicCashback: Double = 0.0
        var cashbackExpiry: Int? = nil
        var cashbackLimit: Double? = nil
        
        for item in cardModel.allCards {
            if "\(item.bank) \(item.card)" == card {
                if item.cardCashback != nil {
                    cashbackArray = Array(item.cardCashback!.keys)
                    cbValueArray = Array(item.cardCashback!.values)
                } else {
                    cashbackArray.append("None")
                    cbValueArray.append(0.0)
                }
                
                basicCashback = item.basicCashback
                cashbackExpiry = item.LimitPeriod
                cashbackLimit = item.cashbackLimit
            }
        }
        
        return (cashbackArray, cbValueArray, basicCashback, cashbackExpiry, cashbackLimit)
    }
    
    func MerchantToArray() -> [String] {
        var merchantArray: [String] = []
        
        for item in merchantModel.allMerchants {
            merchantArray.append(item.name)
        }
        
        return merchantArray
    }
    
    func CbAmountCal() -> Double{
        var extraAmount = (Double(amountStr) ?? 0.0) * CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).1[cbTypeIndex]
        var basicAmount = (Double(amountStr) ?? 0.0) * CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).2
        
        if let lim = CbTypeToArray(card: CardsInfoToArray().0[cardIndex]).4 {
            if extraAmount > lim {
                extraAmount = lim
            }
        }
        
        return basicAmount + extraAmount
    }
}

//#Preview {
//    NewSpendingView()
//}

