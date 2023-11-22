//
//  MerchantNearView.swift
//  CashBackApp
//
//  Created by Kai Tai Lau on 12/11/2023.
//

import SwiftUI
import MapKit
import Contacts
import CoreLocation



struct MerchantNearView: View {
    
    @EnvironmentObject var cardmodel: CardModel
    @EnvironmentObject var merchantmodel: MerchantModel
    @Environment(\.dismiss) private var dismiss
    @State var camera: MapCameraPosition = .automatic
    @State private var showSearch: Bool = false
    @State private var mapSelection: MKMapItem?
    @State private var showLookAroundScene: Bool = false
    @State private var searchResults = [MKMapItem]()
    @State private var showDirection = false
    @State private var route: MKRoute?
    @State var mapItem: MKMapItem?
    @EnvironmentObject var locationManager: LocationManager
    @State private var refreshID: UUID? = nil
    @State private var searchText: String = ""
    @State var showAlert = false
    @State var errorTitle = ""
    @State var errorMessage = ""
    @State var result = ""
    @State var placemark: CLPlacemark?
    @State var showRoute: Bool = false
    @State var updateResult: [(String, String, Image, MKMapItem?, String)]?
    @State var pressedonce: Bool = false
    @State var visited : Bool = false
    @Binding var isContentViewHidden: Bool
    @State var checkdetails:Bool = false
    @State var searchKeywords: [String] = []
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Usercard.bankname, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.cardname, ascending: true),
            NSSortDescriptor(keyPath: \Usercard.docbexpire, ascending: true)
        ],
        animation: .default)
    private var usercard: FetchedResults<Usercard>
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PurchaseHistory.bankname, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.cardname, ascending: true),
            NSSortDescriptor(keyPath: \PurchaseHistory.date, ascending: true)
        ],
        animation: .default)
    private var purch: FetchedResults<PurchaseHistory>
    
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Map(position: $camera, selection: $mapSelection) {
                    UserAnnotation()
                    Marker("", systemImage: "figure.wave", coordinate: locationManager.region.center)
                        .tint(.blue)
                    if mapItem != nil {
                        Marker(item: mapItem!).tag(1)
                    }
                }
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                    MapScaleView()
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 200)
                .task{
                    if !visited{
                        print("Looking for merchants.")
                        setupthestore()
                        await performAutoSearch()
                        updateResult = getShopData()
                        pressedonce = true
                        visited = true
                    }
                }
                Button(action: {
                    Task {
                        visited = false
                        print("Looking for merchants.")
                        setupthestore()
                        await performAutoSearch()
                        updateResult = getShopData()
                        pressedonce = true
                    }
                }) {
                    Text("Press to find near merchant")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                if pressedonce{
                    if let updateResult1 = updateResult {
                        List(updateResult1, id: \.0) {shopData in
                            NavigationLink(destination: RecView(isContentViewHidden: $isContentViewHidden,visited: $visited,merchant: shopData.0, merchantpic: shopData.2, merchantpicid: shopData.4, location: shopData.3,bestUserCashback:calculateUserCashbackbyCard(merchant: shopData.4),bestCashback: calculateCashbackbyCard(merchant: shopData.4))
                                .environmentObject(cardmodel)) {
                                    HStack {
                                        shopData.2
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50)
                                        VStack(alignment: .leading) {
                                            Text(shopData.0)
                                            Text("Distance: \(shopData.1) meters")
                                        }
                                    }
                                }
                            
                        }
                    }
                    
                }
                else {
                    List {
                        Text("Looking for shops...")
                            .font(.caption)
                
                    }
                }
                
            }
            .sheet(isPresented: $showLookAroundScene) {
                GetLookAroundScene(mapItem: $mapSelection, showDirection: $showDirection)
                    .presentationDetents([.height(300)])
                    .presentationBackgroundInteraction(.enabled(upThrough: .height(300)))
                    .presentationCornerRadius(25)
                    .interactiveDismissDisabled(true)
                
            }
            
        }
        .onAppear {
            Task {
                await performAutoSearch()
            }
        }
        .onChange(of: showDirection) { newValue in
            if newValue {
                fetchRoute()
            }
        }
        .onChange(of: showSearch, initial: false) {
            if !showSearch {
                mapSelection = nil
                searchResults = []
                showLookAroundScene = false
                camera = .automatic
            }
        }
        .onChange(of: mapSelection) { _ in
            showLookAroundScene = mapSelection != nil
        }
    }

    
    func performAutoSearch() async {
        let request = MKLocalSearch.Request()
        request.region = locationManager.region
        var allItems: [MKMapItem] = []
        
        for keyword in searchKeywords {
            request.naturalLanguageQuery = keyword
            let results = try? await MKLocalSearch(request: request).start()
            allItems.append(contentsOf: results?.mapItems ?? [])
        }
        self.searchResults = allItems
    }
    
    func fetchRoute() {
        if let mapSelection = mapSelection {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: locationManager.region.center))
            request.destination = mapSelection
            Task {
                let result = try? await MKDirections(request: request).calculate()
                route = result?.routes.first
                withAnimation(.snappy) {
                    showLookAroundScene = false
                    if let rect = route?.polyline.boundingMapRect {
                        camera = .rect(rect)
                    }
                }
                
            }
        }
    }

    func getShopData() -> [(String, String, Image, MKMapItem?, String)] {
        var uniqueShopNames = Set<String>()
        var keywordImageMapping: [String: String] = [:]
        for merchant in merchantmodel.allMerchants {
            keywordImageMapping[merchant.name.lowercased()] = merchant.image
        }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        
        let shopData = searchResults.compactMap { item -> (String, String, Image, MKMapItem?, String)? in
            guard let name = item.name?.lowercased() else { return nil }
            let distance = item.placemark.location?.distance(from: CLLocation(latitude: locationManager.region.center.latitude, longitude: locationManager.region.center.longitude)) ?? 0
            
            if distance > 1000 {
                return nil // Filter out results beyond 1000 meters
            }
            
            if uniqueShopNames.contains(name) {
                return nil // Filter out duplicate shop names
            }
            
            uniqueShopNames.insert(name)
            
            let image: Image
            let pass: String
            let matchingKeywords = keywordImageMapping.keys.filter { name.contains($0) }
            
            if let matchedKeyword = matchingKeywords.first, let mappedImageName = keywordImageMapping[matchedKeyword] {
                image = Image(mappedImageName)
                pass = mappedImageName
            } else {
                return nil // Filter out shops without matching keywords
            }
            
            let formattedDistance = formatter.string(from: NSNumber(value: distance))
            
            return (name, formattedDistance ?? "", image, item, pass)
        }
        
        let sortedShopData = shopData.sorted(by: { Int($0.1) ?? 0 < Int($1.1) ?? 0 })
        return sortedShopData
    }
    
    func updateAddress(placemarks:[CLPlacemark]?,error:Error?) {
        mapItem=nil
        if error != nil {
            errorTitle="Error"
            errorMessage="Geo failed with error :\(error!.localizedDescription)"
            showAlert=true
        } else if let marks = placemarks, marks.count>0 {
            placemark=marks[0] as CLPlacemark
            if let address:CNPostalAddress = placemark!.postalAddress {
                let place = MKPlacemark(coordinate: placemark!.location!.coordinate, postalAddress: address)
                result="\(address.street), \(address.city), \(address.state), \(address.country)"
                mapItem=MKMapItem(placemark: place)
                mapItem?.name = searchText
            }
        }
    }
    func setupthestore() {
        searchKeywords = []
        for merchant in merchantmodel.allMerchants {
            searchKeywords.append(merchant.name)
                //           print(searchKeywords)
        }
    }
    func unphrase(cashback: String?)->[String:Double]{
        var outdict : [String: Double] = [:]
        if let x = cashback{
            
            if x != "" {
                let keyValueArray = x.components(separatedBy: ",")
                for keyValue in keyValueArray {
                    let components = keyValue.components(separatedBy: ":")
                    //                print(components)
                    outdict[(components[0])] = Double(components[1])!
                }
            }
        }
        return outdict
    }
    
    func calculateUserCashbackbyCard(merchant:String)->[Usercard:Double]{
        var odict : [Usercard:Double] = [:]
        if let merchantData:Merchant = merchantmodel.allMerchants.first(where: {$0.image.lowercased().contains(merchant.lowercased())}){
            print("MerchName \(merchantData.name)")
            for card in usercard{
                print("\(card.bankname!) \(card.cardname!)")
                
                if let m = card.spendingcashback{
                    let cashbackDict = unphrase(cashback: m)
                    switch (card.bankname!){
                    case "HSBC":
                        if card.cardname != "Red"{
                            var output : Double = 0.0
                            for category in cashbackDict{
                                if merchantData.HSBC.contains(category.key) && checkOverCashbackLimit(card:card){
                                    output += category.value
                                }
                            }
                            output += card.basicCashback
                            odict[card] = output
                        }
                        else{
                            var output : Double = 0.0
                            for category in cashbackDict{
                                if merchantData.HSBC.contains(category.key){
                                    output += category.value
                                }
                            }
                            output += card.basicCashback
                            odict[card] = output
                        }
                    case "Hang Seng Bank":
                        var output : Double = 0.0
                        for category in cashbackDict{
                            if merchantData.HASE.contains(category.key) && output<0.046 && checkOverCashbackLimit(card:card){
                                output += category.value
                            }
                        }
                        output += card.basicCashback
                        odict[card] = output
                        
                    case "BOCHK":
                        var output : Double = 0.0
                        for category in cashbackDict{
                            if merchantData.BOCHK.contains(category.key) && checkOverCashbackLimit(card:card){
                                output += category.value
                            }
                        }
                        output += card.basicCashback
                        odict[card] = output
                    case "Citibank":
                        var output : Double = 0.0
                        for category in cashbackDict{
                            if merchantData.CITI.contains(category.key){
                                output += category.value
                            }
                        }
                        output += card.basicCashback
                        odict[card] = output
                    case "CITIC":
                        var output : Double = 0.0
                        for category in cashbackDict{
                            if merchantData.CITIC.contains(category.key) && checkOverCashbackLimit(card:card){
                                output += category.value
                            }
                        }
                        output += card.basicCashback
                        odict[card] = output
                    case "Standard Chartered":
                        var output : Double = 0.0
                        for category in cashbackDict{
                            
                            if  card.cardname == "Smart"{
                                if merchantData.SCB.contains(category.key) && checkOverCashbackLimit(card:card){
                                    output += category.value
                                }
                            }
                            else{
                                if merchantData.SCB.contains(category.key){
                                    output += category.value
                                }
                            }
                        }
                        output += card.basicCashback
                        odict[card] = output
                    default:
                        odict[card] = card.basicCashback
                        print("TESTING \(card.bankname!) \(card.cardname!)")
                    }
                    
                }
                else{
                    odict[card] = card.basicCashback
                    print("TESTING \(card.bankname!) \(card.cardname!)")
                }
                print( "\(card.bankname!) \(card.cardname!) : \(odict[card])")
            }
            
        }
            return odict
        }
    
    
    func calculateCashbackbyCard(merchant:String)->[[String]:Double]{
        var odict : [[String]:Double] = [:]
        if let merchantData:Merchant = merchantmodel.allMerchants.first(where: {$0.image.lowercased().contains(merchant.lowercased())}) {
            
            for  card in cardmodel.allCards{
                print("\(card.bank) \(card.card)")
                switch (card.bank){
                case "HSBC":
                    if card.card != "Red"{
                        var output : Double = 0.0
                        if let m = card.cardCashback{
                            for category in m{
                                if merchantData.HSBC.contains(category.key){
                                    output += 0.02
                                }
                            }
                            output += card.basicCashback
                            odict[[card.bank,card.card]] = output
                        }
                        else{
                            if let m = card.cardCashback{
                                for category in m{
                                    if merchantData.HSBC.contains(category.key){
                                        output += category.value
                                    }
                                }
                                output += card.basicCashback
                                odict[[card.bank,card.card]] = output
                            }
                        }
                        
                    }
                case "Hang Seng Bank":
                    var output : Double = 0.0
                    if let m = card.cardCashback{
                        for category in m{
                            if merchantData.HASE.contains(category.key) && category.key.contains("Your Choice") && output<0.046{
                                output += 0.05
                            }
                            else if output==0 && merchantData.HASE.contains(category.key) && category.key.contains("Online") && output<0.046{
                                output += 0.046
                            }
                        }
                    }
                    output += card.basicCashback
                    odict[[card.bank,card.card]] = output
                    
                case "BOCHK":
                    var output : Double = 0.0
                    if let m = card.cardCashback{
                        for category in m{
                            if merchantData.BOCHK.contains(category.key){
                                output += category.value
                            }
                        }
                    }
                    output += card.basicCashback
                    odict[[card.bank,card.card]] = output
                    
                case "Citibank":
                    var output : Double = 0.0
                    if let m = card.cardCashback{
                        for category in m{
                            if merchantData.CITI.contains(category.key){
                                output += category.value
                            }
                        }
                    }
                    output += card.basicCashback
                    odict[[card.bank,card.card]] = output
                case "CITIC":
                    var output : Double = 0.0
                    if let m = card.cardCashback{
                        for category in m{
                            if merchantData.CITIC.contains(category.key){
                                output += category.value
                            }
                        }
                    }
                    output += card.basicCashback
                    odict[[card.bank,card.card]] = output
                case "Standard Chartered":
                    var output : Double = 0.0
                    if let m = card.cardCashback{
                        for category in m{
                            print("Current Cat: \(category)")
                            print(merchantData.SCB)
                            print(merchantData.SCB.contains(category.key))
                            if merchantData.SCB.contains(category.key){
                                output += category.value
                            }
                        }
                    }
                    output += card.basicCashback
                    
                    odict[[card.bank,card.card]] = output
                    
                default:
                    odict[[card.bank,card.card]] = card.basicCashback
                }
                
            }
            
        }
        for e2 in calculateUserCashbackbyCard(merchant: merchant){
            if let keytoRemove = odict.keys.first(where:{$0 == [e2.key.bankname,e2.key.cardname]}){
                odict.removeValue(forKey: keytoRemove)
            }
        }
        print(odict)
        return odict
    }

    func checkOverCashbackLimit(card: Usercard)->Bool{
        var accCB = GetTotalAmount(card: card)
        return accCB < card.cashbackLimit
    }
    
    func GetTotalAmount( card: Usercard) -> Double {
        var total = 0.0
        
        for history in purch {
            if (history.bankname == card.bankname) && (history.cardname == card.cardname) {
                if history.date != nil {
                    if card.bankname != "HSBC"{
                        if (DateToString(date: history.date!, format: "MMMM") == DateToString(date: Date(), format: "MMMM")) && (DateToString(date: history.date!, format: "YYYY") == DateToString(date: Date(), format: "YYYY")) {
                            total += history.cashbackamount
                        }
                    }
                }
                else{
                    if (DateToString(date: history.date!, format: "YYYY") == DateToString(date: Date(), format: "YYYY")) {
                        total += history.cashbackamount
                    }
                }
            }
        }
        return total
    }
        
        
    func DateToString(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
       
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()


//Preview {
//    ContentView()
//}

