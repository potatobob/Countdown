//
//  HomePage.swift
//  CountdownClock
//
//  Created by Admin on 3/8/23.
//

import SwiftUI
import Foundation
import Combine
import UIKit

class UIService : ObservableObject {
    
    static let shared = UIService()

    //MARK: Timer to be used for any interested party
    @Published var generalTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

}

struct countdownData: Identifiable{
    let id = UUID()
    let indexedID = Int()
}
private var componentformatter: DateComponentsFormatter = {
    let componentformatter = DateComponentsFormatter()
    componentformatter.unitsStyle = .short
    componentformatter.formattingContext = .middleOfSentence
    componentformatter.allowedUnits = [.month, .day, .hour, .minute, .second]
    return componentformatter
}()

struct HomePage: View {
    func addItem(){
        instances.append(instances.endIndex)
        defaults!.set(instances, forKey: "instances")
        print(instances)
    }
    //func deleteItem(offsets: IndexSet){
        
    //}
    func loadDate(timestamp: Date) -> String {
        @State var e1 = timestamp.timeIntervalSinceNow
        @State var ee = componentformatter.string(from: e1)!
        ee = ee.replacingLastOccurrenceOfString(",", with: " and", caseInsensitive: false)
        ee = ee.replacingOccurrences(of: "-", with: "")
        return ee
    }
    
    func times(){
        for instance in instances{
            glanceTimes.append(
                Date(timeIntervalSince1970:(defaults?.value(forKey: "timestamp\(instance)") ?? 1704085200.0) as! Double))
        }
    }
    func topics(){
        for instance in instances{
            glanceTopic.append(
                (defaults?.value(forKey: "topic\(instance)") ?? "New Years") as! String)
        }
    }
    func load(day: Date) -> String{
        var time = loadDate(timestamp: day)
        return time
    }
    func delete(at offsets: IndexSet){
        for offset in offsets{
            deletedInstances.append(offset)
        }
        defaults!.set(deletedInstances, forKey: "deleted")
    }
    @EnvironmentObject var UISettings: UIService
    @State var deletedInstances: [Int] = []
    @State var instances: [Int] = []
    @State var glanceTimes: [Date] = []
    @State var glanceTopic: [String] = []
    @State var deleted: [Int] = []
    let defaults = UserDefaults(suiteName: "group.Countdown.com.CountdownClock")
    @State var timing = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    var body: some View {
        NavigationView{
            List{
                ForEach(instances, id: \.self) { instance in
                    if !deletedInstances.contains(instance){
                        NavigationLink(destination: ContentView(id: instance, uuid:UUID()).environmentObject(UIService())) {
                            VStack{
                                Text(glanceTopic[instance % glanceTopic.count])
                                    .multilineTextAlignment(.leading)
                                    .frame(width: CGFloat(Int(UIScreen.main.bounds.width))*0.8, alignment: .leading)
                                if glanceTimes.count != 0{
                                    Text(loadDate(timestamp: glanceTimes[instance % glanceTimes.count]))
                                        .frame(width: CGFloat(Int(UIScreen.main.bounds.width))*0.8, alignment: .leading)
                                }
                            }
                            .padding(EdgeInsets(top: 5, leading: 10,bottom: 5,trailing: 10))
                        }
                        .listRowBackground(RoundedRectangle(cornerRadius: 5)
                        .background(.clear)
                        .foregroundColor(Color(.secondarySystemFill))
                        .padding(EdgeInsets(top: 5, leading: 10,bottom: 5,trailing: 10)))
                        .cornerRadius(90)
                        .listRowSeparator(.hidden)
                    }
                }
                .onDelete(perform: delete)
                
            }
            .listStyle(.plain)
            .onAppear(){
                instances = (defaults?.value(forKey: "instances") ?? []) as! [Int]
                deletedInstances = (defaults?.value(forKey: "deleted") ?? []) as! [Int]
                times()
                topics()
            }
            .onReceive(timing){ inputs in
                glanceTimes = []
                times()
                glanceTopic = []
                topics()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Countdown")
            .navigationBarTitleDisplayMode(.large)
        }
        
    }
}
struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}
