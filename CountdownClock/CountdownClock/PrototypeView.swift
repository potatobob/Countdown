//
//  PrototypeView.swift
//  CountdownClock
//
//  Created by Rohan Sen on 4/12/23.
//

import SwiftUI
import CoreData
import Combine
import Foundation
import UIKit
import CropViewController
import WidgetKit

private var componentformatter: DateComponentsFormatter = {
    let componentformatter = DateComponentsFormatter()
    componentformatter.unitsStyle = .short
    componentformatter.formattingContext = .middleOfSentence
    componentformatter.allowedUnits = [.month, .day, .hour, .minute, .second]
    return componentformatter
}()
struct PrototypeView: View {
    func loadDate(timestamp: Date) -> String {
        @State var e1 = timestamp.timeIntervalSinceNow
        @State var ee = componentformatter.string(from: e1)!
        ee = ee.replacingLastOccurrenceOfString(",", with: " and", caseInsensitive: false)
        ee = ee.replacingOccurrences(of: "-", with: "")
        return ee
    }
    func loadSchem() -> FetchedResults<Item>{
        var DBitems = items
        return DBitems
    }
    @Environment(\.editMode) private var editMode
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date1970, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State var refresh = false
    @State public var time_since: Date = Date(timeIntervalSince1970: 1704085200)
    @State public var topic: String = "New Years"
    @State var e_converted = "loading"
    @State var show = false
    @State var showPicker = false
    @State var showCrop = false
    @State public var isNew = false
    @State public var image = UIImage()
    @State public var useBackgroundToggle = false
    @State public var useBackground = false
    @State public var textcolor = Color(.label)
    @State public var bgcolor = Color(.systemBackground)
    @State public var widgettextcolor = Color(.label)
    @State public var widgetbgcolor = Color(.systemBackground)
    @State private var currentSheet: SheetType = .imagePick
    @State private var actionSheetIsPresented = false
    //@State private var croppingStyle = CropViewCroppingStyle.default
    @State private var croppedRect = CGRect.zero
    @State private var croppedAngle = 0
    @State private var originalImage: UIImage?
    @State private var realImage = false
    @State private var fontOptions = ["light", "regular", "bold", "extra bold"]
    @State private var fontChoice = ".regular"
    @State private var beforeorafter = "after"
    @State private var dataModel: [Item?] = []
    @State private var uuid = UUID()
    func update() {
       refresh.toggle()
    }
    func colorBG(color: UIColor){
        image = UIImage(color: color, size: CGSize(width: 100, height: 100)) ?? UIImage()
        image = self.image
        saveImage(imageName: "\(uuid).png", image: self.image)
        realImage = true
        useBackground = true
        
    }
    func presentPicker(){
        showPicker.toggle()
    }
    func presentcrop(){
        showPicker.toggle()
        currentSheet = .imageCrop
    }
    func showSheet(){
        show.toggle()
    }
    func dismissSheet(){
        showSheet()
        let defaults = UserDefaults(suiteName: "group.Countdown.com.CountdownClock")
        var textcolorchange = UIColor(textcolor).rgb()
        sync()
        updateItem(id: uuid, date: time_since, topic: topic, background:  useBackground, bgtoggle: useBackgroundToggle, realImage: realImage, bgcolor: UIColor(bgcolor).rgb()!, textColor: textcolorchange!, widgetBgColor: UIColor(widgetbgcolor).rgb()!, widgetTextColor: UIColor(widgettextcolor).rgb()!, firstLaunch: false)
        WidgetCenter.shared.reloadAllTimelines()
    }
    @State var timing = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    var body: some View {
        NavigationView{
            List{
                ForEach(items, id: \.self){ item in
                    NavigationLink(destination: ContentView(id: 0, uuid: item.uuid ?? UUID()).environmentObject(UIService())) {
                        VStack{
                            Text(item.topic ?? "test")
                                .multilineTextAlignment(.leading)
                                .padding(.top)
                                .frame(width: CGFloat(Int(UIScreen.main.bounds.width))*0.7, height: 5, alignment: .leading)
                            
                            Text("e\(refresh)" as String)
                                .hidden()
                                .frame(width:0,height:0)
                            Text(loadDate(timestamp:item.date1970 ?? Date(timeIntervalSince1970: 1704085200)))
                                .frame(width: CGFloat(Int(UIScreen.main.bounds.width))*0.7, alignment: .leading)
                        }
                    }
                    .frame(width: CGFloat(Int(UIScreen.main.bounds.width))*0.7, alignment: .leading)
                }
                .onDelete(perform: deleteItems)
                .padding(EdgeInsets(top: 5, leading: 0,bottom: 5,trailing: 0))
                .listRowBackground(RoundedRectangle(cornerRadius: 5)
                    .background(.clear)
                    .foregroundColor(Color(.secondarySystemFill))
                    .padding(EdgeInsets(top: 5, leading: 0,bottom: 5,trailing: 0)))
                .listRowSeparator(.hidden)
                .frame(width:UIScreen.main.bounds.width)
                .frame(width: CGFloat(Int(UIScreen.main.bounds.width)), alignment: .leading)
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onReceive(timing){input in
                update()
            }
        }
    }
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.date1970 = Date(timeIntervalSince1970: 1404085200)
            newItem.topic = "New Years"
            newItem.background = false
            newItem.backgroundtoggle = false
            newItem.realimage = false
            newItem.bgcolor = Int64(UIColor(Color(.systemBackground)).rgb()!)
            newItem.textColor = Int64(UIColor(Color(.label)).rgb()!)
            newItem.widgetBgColor = Int64(UIColor(Color(.systemBackground)).rgb()!)
            newItem.widgetTextColor = Int64(UIColor(Color(.label)).rgb()!)
            newItem.firstLaunch = true
            newItem.uuid = UUID()
            uuid = newItem.uuid ?? UUID()
            do {
                try viewContext.save() 
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
        print("added")
        showSheet()
    }
    private func updateItem(id: UUID, date: Date, topic: String, background: Bool, bgtoggle: Bool, realImage: Bool, bgcolor: Int, textColor: Int, widgetBgColor: Int, widgetTextColor: Int, firstLaunch: Bool) {
        withAnimation {
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "uuid == %@", id as CVarArg)

            do {
                let items = try viewContext.fetch(fetchRequest)
                guard let itemToUpdate = items.first else {
                    print("Item not found")
                    return
                }
                
                itemToUpdate.date1970 = date
                itemToUpdate.topic = topic
                itemToUpdate.background = background
                itemToUpdate.backgroundtoggle = bgtoggle
                itemToUpdate.realimage = realImage
                itemToUpdate.bgcolor = Int64(bgcolor)
                itemToUpdate.textColor = Int64(textColor)
                itemToUpdate.widgetBgColor = Int64(widgetBgColor)
                itemToUpdate.widgetTextColor = Int64(widgetTextColor)
                itemToUpdate.firstLaunch = false
                
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
        print("updated")
    }
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

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
}

struct PrototypeView_Previews: PreviewProvider {
    static var previews: some View {
        PrototypeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
