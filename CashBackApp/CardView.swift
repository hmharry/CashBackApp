//
//  CardView.swift
//  CashBackApp
//
//  Created by Hei Man on 12/11/2023.
//

import SwiftUI
import CoreData


struct CardView: View {
    //@Environment(\.managedObjectContext) private var viewContext
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardModel: CardModel
    @FetchRequest(
        entity: Usercard.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Usercard.bankname, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.cardname, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.docbexpire, ascending: true)
        ],
        animation: .default)

    private var items: FetchedResults<Usercard>
    @FetchRequest(
        entity: PurchaseHistory.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PurchaseHistory.bankname, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.cardname, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.date, ascending: true)
        ],
        animation: .default)
    private var items2: FetchedResults<PurchaseHistory>
    @State var showAllCardList : Bool = false
    @State var userCardExist : Array<Bool> = []
   

    
    var body: some View {
        VStack{
            NavigationView{
                
                
                List{
                    ForEach(items, id: \.self) { item in
                        NavigationLink(                        destination: OwnChoiceView(card: item,duePayment: item.dopayment ??  Date(), dueCashback: item.docbexpire ?? Date())){
                            
                            
                            HStack{
                                Image(item.cardimage!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150,height: 90,alignment: .leading)
                                VStack{
                                    HStack{
                                        Text(item.bankname!)
                                            .font(.title2)
                                        Spacer()
                                    }
                                    HStack{
                                        Text(item.cardname!)
                                            .font(.title3)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }.toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            updateUserCard()
                            showAllCardList = true
     //                       print("Test")
       //                     print(userCardExist)
                        }, label: {
                            Text("Edit")
                        })
                    }
                }.sheet(isPresented: $showAllCardList, content: {
                    AllCardView(cardModel: cardModel,items:items,items2: items2, userCardExist: $userCardExist)
                        .environmentObject(cardModel)
                    
                    
                }).onAppear(perform: {
                    updateUserCard()
                })
                
            }
  //          Text("Our Picks:").font(.largeTitle)
            
            
            
        }
    }
    func updateUserCard(){
        userCardExist = []
        var flag: Bool = false
        for card in cardModel.allCards{
            if items.isEmpty{
                userCardExist.append(false)
            }
            for item in items{
 //               print("UPdating")
   //             print(item.cardname!)
                if item.cardname == card.card && item.bankname == card.bank{
                    userCardExist.append(true)
                    flag = true
   //                 print("Has card")
     //               print(userCardExist)
                    break
                }
            }
            if flag == false && !items.isEmpty{
                userCardExist.append(false)
  //              print("doesn't have card")
    //            print(userCardExist)
            }
            else{
                flag = false
            }
        }
  //      print("Here is cardview")
    //    print(userCardExist)
    }
                        
                        
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
        
        
#Preview {
    CardView()
}
