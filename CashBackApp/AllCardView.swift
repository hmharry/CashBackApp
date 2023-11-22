//
//  AllCardView.swift
//  CashBackApp
//
//  Created by Hei Man on 14/11/2023.
//

import SwiftUI
import CoreData
import UIKit

struct AllCardView: View {
    @Environment (\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject  var cardModel: CardModel
    var items: FetchedResults<Usercard>
    var items2: FetchedResults<PurchaseHistory>
    @Binding var userCardExist: [Bool]
    
    
    func updateUserCard(){
        userCardExist = []
        var flag: Bool = false
        for card in cardModel.allCards{
            if items.isEmpty{
                userCardExist.append(false)
            }
            for item in items{
                if item.cardname == card.card && item.bankname == card.bank{
                    userCardExist.append(true)
                    flag = true
                    break
                }
            }
            if flag == false && !items.isEmpty{
                userCardExist.append(false)
            }
            else{
                flag = false
            }
        }
//        print(userCardExist)
    }
    
    func checkData(item: Card) -> Bool {
            let managedContext = viewContext

            // Create a fetch request for the Usercard entity with a predicate
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Usercard")

            // Specify the conditions for checking using a predicate
        fetchRequest.predicate = NSPredicate(format: "bankname == %@ AND cardname == %@", item.bank, item.card)

            do {
                // Fetch the Usercard entities that match the request
                let matchingUsercards = try managedContext.fetch(fetchRequest)

                return !matchingUsercards.isEmpty
            } catch let error as NSError {
                print("Could not fetch data. \(error), \(error.userInfo)")
                return false
            }
        }

    
    
    
    
    
    func updateExist(){
        for i in 0..<userCardExist.count{
            let ifUsercardContainsBankcard = checkData(item: cardModel.allCards[i])
            if userCardExist[i] && !ifUsercardContainsBankcard{
                let newItem = Usercard(context: viewContext)
                newItem.id = UUID()
                newItem.bankname = cardModel.allCards[i].bank
                newItem.cardname = cardModel.allCards[i].card
                if let _ = cardModel.allCards[i].cardCashback{
                    newItem.spendingcashback = convertdict(dict:cardModel.allCards[i].cardCashback!)!
                }
                if newItem.bankname! == "HSBC" && (newItem.cardname! == "Gold" || newItem.cardname! == "Platinum"){
                    switch (newItem.cardname){
                    case "Gold":
                        for card in items{
                            if card.cardname! == "Platinum" && card.bankname! == "HSBC"{
                                newItem.spendingcashback = card.spendingcashback!
                                break
                            }
                        }
                    case "Platinum":
                        for card in items{
                            if card.cardname! == "Gold" && card.bankname! == "HSBC"{
                                newItem.spendingcashback = card.spendingcashback
                                break
                            }
                        }
                    default:
                        newItem.spendingcashback = newItem.spendingcashback
                    }
                }
                newItem.cardimage = cardModel.allCards[i].cardImage
                newItem.basicCashback = cardModel.allCards[i].basicCashback
                newItem.promo = cardModel.allCards[i].promo
                
                if let retrive=cardModel.allCards[i].cashbackLimit {
                    newItem.cashbackLimit =  retrive
                }
                newItem.dopayment = Date()
                newItem.docbexpire = Date()
                newItem.spending = 0
                newItem.cashbackGain = 0
            }
                else if userCardExist[i] == false && ifUsercardContainsBankcard{
                    deletePurchase(item: cardModel.allCards[i])
                    deleteitem(item: cardModel.allCards[i])
                    
                }
            
                
                
                
                
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
                
            
        }
   
        
    }
    func deletePurchase(item:Card){
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PurchaseHistory")
        fetchRequest.predicate = NSPredicate(format: "bankname == %@ AND cardname == %@",item.bank, item.card)
        do{
            let purch = try viewContext.fetch(fetchRequest)
            for case let purchase as NSManagedObject in purch{
                viewContext.delete(purchase)
            }
        }
         catch let error as NSError {
            print("Could not fetch or delete data. \(error), \(error.userInfo)")
        }
    }
    func deleteitem(item: Card) {
           // Create a fetch request for the UserCard entity with a predicate
           let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Usercard")

           // Specify the conditions for deletion using a predicate
        fetchRequest.predicate = NSPredicate(format: "bankname == %@ AND cardname == %@",item.bank, item.card)

           do {
               // Fetch the UserCard entities that match the request
               let usercards = try viewContext.fetch(fetchRequest)

               // Loop through the fetched entities and delete them
               for case let usercard as NSManagedObject in usercards {
                   viewContext.delete(usercard)
               }

               // Save the changes to the managed object context
               try viewContext.save()

               print("Data deleted successfully.")
           } catch let error as NSError {
               print("Could not fetch or delete data. \(error), \(error.userInfo)")
           }
          
    }
    
    func convertdict(dict:[String: Double])-> String?{
        do{
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: .utf8)
            let crit :  Set<Character> = ["\"","{","\\","}"]
            var m = jsonString!
                m.removeAll(where: { crit.contains($0)
            })
    //            print(jsonString!)
                return m
            } catch {
                print("Error converting dictionary to string: \(error)")
                return nil
            }
    }
    
    var body: some View {
        NavigationView{
            List{
                ForEach (cardModel.allCards){card in
                    Toggle(isOn: $userCardExist[Int(card.id)!],label: {
                        HStack{
                            Image(card.cardImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150,height: 90,alignment: .leading)
                            VStack{
                                HStack{
                                    Text("\(card.bank) \(card.card)").frame(alignment: .leading)
                                        .font(.title3)
                                    Spacer()
                                    
                                }
                                HStack{
                                    Image(systemName: "circle.fill")
                                        .scaleEffect(0.5)
                                    Text(card.promo)
                                        .font(.caption)
                                        .frame(alignment: .leading)
                                    Spacer()
                                }
                            }
                        }
                        
                    }) .toggleStyle(CheckboxStyle())
                        .frame(alignment: .leading)
                }
                //}.pickerStyle(.menu)
            }/*.onAppear().task {
              updateExist()
              }*/
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action:{
   //                     print("UPD")
     //                   print(userCardExist)
                        
                        updateExist()
                        do {
                            try viewContext.save()
                        } catch {
                            // Replace this implementation with code to handle the error appropriately.
                            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                            let nsError = error as NSError
      //                      print("ERRX")
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                        dismiss()
                    } ,label: {
                        Text("Done")
                    })
                }
            }
            .navigationTitle("Edit")
        }
            
    }
    
    
    
}

//#Preview {
//    AllCardView(items:items).environment(\.managedObjectContext, CoreDataManager.previewUsercard.container.viewContext)
//    
//}












struct CheckboxStyle: ToggleStyle {
 
    func makeBody(configuration: Self.Configuration) -> some View {
 
        return HStack {
 
            configuration.label
 
            Spacer()
 
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .font(.system(size: 20, weight: .bold, design: .default))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }// Information found in :https://www.appcoda.com/swiftui-toggle-style/
 
    }
}
