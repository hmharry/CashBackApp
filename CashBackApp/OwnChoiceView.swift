//
//  OwnChoiceView.swift
//  CashBackApp
//
//  Created by Hei Man on 16/11/2023.
//

import SwiftUI

struct OwnChoiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State var card: Usercard
    @State var duePayment = Date()
    @State var dueCashback = Date()
    @State var valueinCat: [String : Double] = [:]
    @State var valueEditable: [String: Double] = [:]
    @State var haseEditable: [String: Bool] = [:]
    @State var showAlert = false
    @Environment(\.dismiss) private var dismiss
    func binding(for key: String) -> Binding<Bool> {
            Binding(
                get: { self.haseEditable[key] ?? false },
                set: { self.haseEditable[key] = $0 }
            )
        }
    func changeCat (input: String?){
        if let x = input{
            if x != "" {
                let keyValueArray = x.components(separatedBy: ",")
                for keyValue in keyValueArray {
                    let components = keyValue.components(separatedBy: ":")
    //                print(components)
                    valueinCat[(components[0])] = Double(components[1])!
            }
            }
//            print(valueinCat)
            if card.bankname == "HSBC" || card.bankname == "Hang Seng Bank"{
                for k in valueinCat.keys{
                    if k.contains("Your Choice"){
                        valueEditable[k] = valueinCat[k]!
                        if card.bankname == "Hang Seng Bank"{
                            haseEditable[k] = (valueinCat[k] == 0.05)
                        }
                    }
                }
            }
        }
    }

    func changeBacktoOriginal(){
        card.dopayment = duePayment
        card.docbexpire = dueCashback
        for (key,val) in valueEditable{
//            print("Key:\(key)")
            if let vOld = valueinCat[key]{
                if vOld != val{
                    valueinCat[key] = val
                }
            }
            if card.bankname == "HSBC" && card.cardname != "Red"{
                var sum = 0.0
                for i in valueEditable.values{
                    sum+=i
                }
                if sum>0.02{
                    showAlert = true
                }
            }
            if card.bankname == "Hang Seng Bank"{
                if haseEditable[key] == false{
                    valueinCat[key] = 0.0
                }
                else{
                    valueinCat[key] = 0.05
                }
            }
        }
        card.spendingcashback = valueinCat.map { "\($0.key):\($0.value)" }.joined(separator: ",")
        
        
    }
    
     func shouldDisableToggle(for key: String) -> Bool {
        // Disable toggle if there are already two true toggles
        return haseEditable[key] == false && haseEditable.filter({ $0.value == true }).count >= 2
    }
    
    
    
    
    var body: some View {
        VStack{
            Image(card.cardimage!)
                .resizable()
                .scaledToFit()
                .frame(width: 300 , height: 200)
            Text("\(card.bankname!) \(card.cardname!)")
                .font(.title2)
            
           
            Form(
                content:{HStack{
                Text("Payment due date:")
                Spacer()
                    DatePicker(selection: $duePayment, displayedComponents: [.date]){}
                
                }
                HStack{
                        Text("Cashback due date:")
                        Spacer()
                        DatePicker(selection: $dueCashback, displayedComponents: [.date]){}
                    }
                    if card.bankname! == "HSBC" || card.bankname! == "Hang Seng Bank" {
                        if card.bankname! == "HSBC" && card.cardname! != "Red"{
                            
                            List{
                                ForEach(valueEditable.sorted(by: >),id: \.key){
                                    key , value in
                                    Picker("\(key)",selection:$valueEditable[key]) {
                                        Text("0X").tag(Optional(0.0))
                                        Text("1X").tag(Optional(0.004))
                                        Text("2X").tag(Optional(0.008))
                                        Text("3X").tag(Optional(0.012))
                                        Text("4X").tag(Optional(0.016))
                                        Text("5X").tag(Optional(0.02)) // Tried a lot of methods but in vein
                                    }
                                    
                                    
                                }
                            }
                        }
                            else if card.bankname! == "Hang Seng Bank"{
                                List{
                                    ForEach(haseEditable.sorted(by: {$0.key <  $1.key}),id: \.key){
                                        key , value in
                                        
                                        Toggle(isOn: self.binding(for: key)){
                                            Text(key)
                                        }
                                        .disabled(self.shouldDisableToggle(for: key))
                                         
                                        
                                    }
                                
                            }
                        }
                    }
                }).onAppear{
                    changeCat(input: card.spendingcashback)
  //                  print(card.cardname!)
  //                  print(card.bankname!)
                
                }
                
        } .navigationBarBackButtonHidden(true)
            .alert(isPresented: $showAlert) {
                                    Alert(
                                        title: Text("Total Exceeded"),
                                        message: Text("The total of selected values cannot exceed 5X."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
            .toolbar {
                
                // 2
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    Button {
                        // 3
                        changeBacktoOriginal()
                        print(card.dopayment!)
                        
                        if !showAlert{
                            do {
                                try viewContext.save()
                            } catch {
                                let nsError = error as NSError
                                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                            }
                            dismiss()
                        
                        }
                    } label: {
                        // 4
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back")
                        }
                    }
                }
            }
        
        
        
        
        
    }
}

//#Preview {
//    OwnChoiceView()
//}
