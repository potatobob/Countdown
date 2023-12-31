//
//  ContentView.swift
//  CountdownClock
//
//  Created by Admin on 1/31/23.
//

import SwiftUI
import CoreData
import Combine
import Foundation
import UIKit
import WidgetKit
import CropViewController

enum SheetType {
        case imagePick
        case imageCrop
    }
public extension UIImage {
      convenience init?(color: UIColor, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
      }
    }
extension UIColor {
    convenience init(rgb: Int) {
        let iBlue = rgb & 0xFF
        let iGreen =  (rgb >> 8) & 0xFF
        let iRed =  (rgb >> 16) & 0xFF
        let iAlpha =  (rgb >> 24) & 0xFF
        self.init(red: CGFloat(iRed)/255, green: CGFloat(iGreen)/255,
                  blue: CGFloat(iBlue)/255, alpha: CGFloat(iAlpha)/255)
    }
}
extension UIColor {

    func rgb() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)

            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}

public struct ImagePickerView: UIViewControllerRepresentable {

    private var croppingStyle = CropViewCroppingStyle.default
    private let sourceType: UIImagePickerController.SourceType
    private let onCanceled: () -> Void
    private let onImagePicked: (UIImage?) -> Void
    
    public init(croppingStyle: CropViewCroppingStyle, sourceType: UIImagePickerController.SourceType, onCanceled: @escaping () -> Void, onImagePicked: @escaping (UIImage?) -> Void) {
        self.croppingStyle = croppingStyle
        self.sourceType = sourceType
        self.onCanceled = onCanceled
        self.onImagePicked = onImagePicked
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        if croppingStyle == .circular {
            imagePicker.modalPresentationStyle = .popover
//        imagePicker.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
            //imagePicker.preferredContentSize = CGSize(width: 320, height: 568)
        }
        imagePicker.sourceType = self.sourceType
        imagePicker.allowsEditing = false
        imagePicker.delegate = context.coordinator
        return imagePicker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onCanceled: self.onCanceled,
            onImagePicked: self.onImagePicked
        )
    }

    final public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        private let onCanceled: () -> Void
        private let onImagePicked: (UIImage?) -> Void

        init(onCanceled: @escaping () -> Void, onImagePicked: @escaping (UIImage?) -> Void) {
            self.onCanceled = onCanceled
            self.onImagePicked = onImagePicked
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            
            guard let image = info[.originalImage] as? UIImage else {
                picker.dismiss(animated: true) {
                    self.onImagePicked(nil)
                }
                return
            }
            
            picker.dismiss(animated: true) {
                self.onImagePicked(image)
            }
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.onCanceled()
            }
        }
    }
}

public struct ImageCropView: UIViewControllerRepresentable {
    
    private var croppingStyle = CropViewCroppingStyle.default
    private let originalImage: UIImage
    private let onCanceled: () -> Void
    private let onImageCropped: (UIImage,CGRect,Int) -> Void
    
    @Environment(\.presentationMode) private var presentationMode

    public init(croppingStyle: CropViewCroppingStyle, originalImage: UIImage, onCanceled: @escaping () -> Void, success onImageCropped: @escaping (UIImage,CGRect,Int) -> Void) {
        self.croppingStyle = croppingStyle
        self.originalImage = originalImage
        self.onCanceled = onCanceled
        self.onImageCropped = onImageCropped
    }

    public func makeUIViewController(context: Context) -> CropViewController {
        let cropController = CropViewController(croppingStyle: croppingStyle, image: originalImage)
//        cropController.modalPresentationStyle = .fullScreen
        cropController.delegate = context.coordinator

        // Uncomment this if you wish to provide extra instructions via a title label
        cropController.title = "Crop Image"
    
        // -- Uncomment these if you want to test out restoring to a previous crop setting --
        //cropController.angle = 90 // The initial angle in which the image will be rotated
        let screensize = UIScreen.main.bounds
        cropController.customAspectRatio = CGSize(width: screensize.width, height: screensize.size.height)
        //cropController.imageCropFrame = CGRect(x: 0, y: 0, width: screensize.width, height: screensize.height) //The initial frame that the crop controller will have visible.
        cropController.resetButtonHidden = true
        cropController.rotateButtonsHidden = true
        // -- Uncomment the following lines of code to test out the aspect ratio features --
        cropController.aspectRatioPreset = TOCropViewControllerAspectRatioPreset(rawValue: Int((screensize.width/screensize.height)))!; //Set the initial aspect ratio as a square
        cropController.aspectRatioLockEnabled = true // The crop box is locked to the aspect ratio and can't be resized away from it
        //cropController.resetAspectRatioEnabled = false // When tapping 'reset', the aspect ratio will NOT be reset back to default
        cropController.aspectRatioPickerButtonHidden = true
    
        // -- Uncomment this line of code to place the toolbar at the top of the view controller --
        cropController.toolbarPosition = .top
        
        //cropController.rotateButtonsHidden = true
        //cropController.rotateClockwiseButtonHidden = true
    
        //cropController.doneButtonTitle = "Title"
        //cropController.cancelButtonTitle = "Title"
        
        //cropController.toolbar.doneButtonHidden = true
        //cropController.toolbar.cancelButtonHidden = true
        //cropController.toolbar.clampButtonHidden = true
        
        return cropController
    }

    public func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onDismiss: { self.presentationMode.wrappedValue.dismiss() },
            onCanceled: self.onCanceled,
            onImageCropped: self.onImageCropped
        )
    }

    final public class Coordinator: NSObject, CropViewControllerDelegate {

        private let onDismiss: () -> Void
        private let onImageCropped: (UIImage,CGRect,Int) -> Void
        private let onCanceled: () -> Void

        init(onDismiss: @escaping () -> Void, onCanceled: @escaping () -> Void, onImageCropped: @escaping (UIImage,CGRect,Int) -> Void) {
            self.onDismiss = onDismiss
            self.onImageCropped = onImageCropped
            self.onCanceled = onCanceled
        }

        public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {

            self.onImageCropped(image, cropRect, angle)
            self.onDismiss()
        }
        
        public func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            
            self.onImageCropped(image, cropRect, angle)
            self.onDismiss()
        }
        
        public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
            
            self.onCanceled()
            self.onDismiss()
        }
    }
}
extension UIImage {
    
    static func removeImage(fileName: String){
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                print("Removed image")
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
    }
    
}
func saveImage(imageName: String, image: UIImage) {


 guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

    let fileName = imageName
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    guard let data = image.jpegData(compressionQuality: 1) else { return }

    //Checks if file exists, removes it if so.
    if FileManager.default.fileExists(atPath: fileURL.path) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
            print("Removed old image")
        } catch let removeError {
            print("couldn't remove file at path", removeError)
        }

    }

    do {
        try data.write(to: fileURL)
    } catch let error {
        print("error saving file with error", error)
    }

}



func loadImageFromDiskWith(fileName: String) -> UIImage? {

  let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

    let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
    let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

    if let dirPath = paths.first {
        let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
        let image = UIImage(contentsOfFile: imageUrl.path)
        return image

    }

    return nil
}
private var componentformatter: DateComponentsFormatter = {
    let componentformatter = DateComponentsFormatter()
    componentformatter.unitsStyle = .full
    componentformatter.includesApproximationPhrase = true
    componentformatter.formattingContext = .middleOfSentence
    componentformatter.allowedUnits = [.month, .day, .hour, .minute, .second]
    return componentformatter
}()

extension String
{
    func replacingLastOccurrenceOfString(_ searchString: String,
                                         with replacementString: String,
                                         caseInsensitive: Bool = true) -> String
    {
        let options: String.CompareOptions
        if caseInsensitive {
            options = [.backwards, .caseInsensitive]
        } else {
            options = [.backwards]
        }

        if let range = self.range(of: searchString,
                options: options,
                range: nil,
                locale: nil) {

            return self.replacingCharacters(in: range, with: replacementString)
        }
        return self
    }
}
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
struct ContentView: View {
    var id: Int
    var uuid: UUID
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date1970, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    func getItem(with uuid: UUID?) -> Item? {
        guard let id = uuid else { return nil }
        let request: NSFetchRequest<Item> = Item.fetchRequest() // 1.
        request.predicate = NSPredicate(format: "uuid == %@", id as CVarArg) // 2.
        do {
            let items = try viewContext.fetch(request) // 3.
            return items.first
        } catch {
            print("Error fetching item with id \(id): \(error)")
            return nil
        }
    }
    @State var timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    
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
    @State private var croppingStyle = CropViewCroppingStyle.default
    @State private var croppedRect = CGRect.zero
    @State private var croppedAngle = 0
    @State private var originalImage: UIImage?
    @State private var realImage = false
    @State private var fontOptions = ["light", "regular", "bold", "extra bold"]
    @State private var fontChoice = ".regular"
    @State private var beforeorafter = "after"
    @State private var dataModel: [Item?] = []
    @EnvironmentObject var UISettings: UIService
    let defaults = UserDefaults(suiteName: "group.Countdown.com.CountdownClock")
    func load() -> String {
        @State var e = time_since.timeIntervalSinceNow
        e_converted = componentformatter.string(from: e)!
        e_converted = e_converted.replacingLastOccurrenceOfString(",", with: " and", caseInsensitive: false)
        e_converted = e_converted.replacingOccurrences(of: "-", with: "")
        return e_converted
    }
    func showSheet(){
        show.toggle()
    }
    func dismissSheet(){
        showSheet()
        let defaults = UserDefaults(suiteName: "group.Countdown.com.CountdownClock")
        var textcolorchange = UIColor(textcolor).rgb()
        defaults!.set(textcolorchange, forKey: "color\(id)")
        defaults!.set(UIColor(widgettextcolor).rgb(), forKey: "textcolor\(id)")
        defaults!.set(UIColor(widgetbgcolor).rgb(), forKey: "bgcolor\(id)")
        defaults!.set(time_since.timeIntervalSince1970, forKey: "timestamp\(id)")
        defaults!.set(useBackground, forKey: "bg\(id)")
        defaults!.set(useBackgroundToggle, forKey: "bgtoggle\(id)")
        defaults!.set(realImage, forKey: "realImage\(id)")
        defaults!.set(UIColor(bgcolor).rgb(), forKey: "appBg\(id)")
        defaults!.set(topic, forKey: "topic\(id)")
        sync()
        updateItem(id: uuid, date: time_since, topic: topic, background:  useBackground, bgtoggle: useBackgroundToggle, realImage: realImage, bgcolor: UIColor(bgcolor).rgb()!, textColor: textcolorchange!, widgetBgColor: UIColor(widgetbgcolor).rgb()!, widgetTextColor: UIColor(widgettextcolor).rgb()!, firstLaunch: false)
        WidgetCenter.shared.reloadAllTimelines()
    }
    func sync(){
        let defaults = UserDefaults(suiteName: "group.countdown.com.CountdownClock")
        defaults!.set(Int(time_since.timeIntervalSince1970), forKey: "timestamp\(id)")
        defaults!.set(topic, forKey: "topic\(id)")
        defaults!.set(topic, forKey: "topic\(id)")
        defaults!.set(UIColor(widgettextcolor).rgb(), forKey: "textcolor\(id)")
        defaults!.set(UIColor(widgetbgcolor).rgb(), forKey: "bgcolor\(id)")
        WidgetCenter.shared.reloadAllTimelines()
        print("synced")
    }
    func fix() -> Bool{
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore\(id)")
        if !launchedBefore {
            print("First launch, setting UserDefault.")
            UserDefaults.standard.set(true, forKey: "launchedBefore\(id)")
            return true
            
        } else {
            return false
        }
        
       
        

    }

    func setDate() -> Date{
        if isNew == true{
            return [getItem(with: uuid)][0]?.date1970 ?? Date(timeIntervalSince1970: 1704085200)
        } else {
            var data = defaults?.value(forKey: "timestamp\(id)") ?? 1704085200.0
            //time_since = Date(timeIntervalSince1970: data as! TimeInterval)
            time_since = items[id].date1970 ?? Date(timeIntervalSince1970: 1704085200)
            return [getItem(with: uuid)][0]?.date1970 ?? Date(timeIntervalSince1970: 1704085200)
        }
        return Date(timeIntervalSince1970: 1704085200)
    }
    func setTopic() -> String{
        if isNew == true{
            return [getItem(with: uuid)][0]?.topic ?? "Filler"
        } else {
            
            return [getItem(with: uuid)][0]?.topic ?? "Filler"
        }
        
    }
    func setBg() -> Bool{
        if isNew == true{
            colorBG(color: .systemBackground)
            return false
        } else {
            
            return [getItem(with: uuid)][0]?.background ?? false
        }
    }
    func setBgToggle() -> Bool{
        if isNew == true{
            return false
        } else {
            let data = defaults?.value(forKey: "bgtoggle\(id)") ?? false
            useBackgroundToggle = data as! Bool
            return [getItem(with: uuid)][0]?.backgroundtoggle ?? false
        }
    }
    func setTextColor() -> Color{
        
        if isNew == true{
            var textColor = getItem(with: uuid)?.textColor
            var idfk = UIColor(rgb: Int([getItem(with: uuid)][0]!.textColor))
            return Color(idfk)
           
        } else {
            var textColor = getItem(with: uuid)?.textColor
            var idfk = UIColor(rgb: Int([getItem(with: uuid)][0]!.textColor))
            return Color(idfk)
        }
        
        //return Color(.label)
    }
    func setWidgetTextColor() -> Color{
        if isNew == true{
            return Color(.label)
           
        } else {
            var rawColor = self.defaults?.value(forKey: "textcolor\(id)") ?? Int(UIColor(Color(.label)).rgb()!)
            var UIbgcolor = UIColor(rgb: rawColor as! Int)
            return Color(UIbgcolor)
        }
    }
    func setWidgetBGColor() -> Color{
        if isNew == true{
            return Color(.systemBackground)
           
        } else {
            var rawColor = self.defaults?.value(forKey: "bgcolor\(id)") ?? Int(UIColor(Color(.systemBackground)).rgb()!)
            var UIbgcolor = UIColor(rgb: rawColor as! Int)
            return Color(UIbgcolor)
        }
    }

    func setStatus() -> Bool{
        if isNew == true{
            return false
        }
        else{
            var data = defaults?.value(forKey: "bgtoggle\(id)") ?? false
            var real = data as! Bool
            return real
            
        }
    }
    func setBGColor() -> Color{
        if isNew == true{
            var textColor = getItem(with: uuid)?.bgcolor
            var idfk = UIColor(rgb: Int([getItem(with: uuid)][0]!.bgcolor))
            return Color(idfk)
           
        } else {
            var textColor = getItem(with: uuid)?.bgcolor
            var idfk = UIColor(rgb: Int([getItem(with: uuid)][0]!.bgcolor))
            return Color(idfk)
        }
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
    var body: some View {
        NavigationView{
            VStack{
                VStack{
                    Spacer()
                    if (Int(Date().timeIntervalSince1970) - Int(time_since.timeIntervalSince1970) >= 0){
                        Text("The time since \(topic) is:")
                            .font(.largeTitle)
                            .padding(.bottom)
                    } else if (Int(Date().timeIntervalSince1970) - Int(time_since.timeIntervalSince1970) <= 0){
                        Text("The time until \(topic) is:")
                            .font(.largeTitle)
                            .padding(.bottom)
                    }
                    Text("\(e_converted)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .onReceive(timer) { input in
                            load()}
                    Spacer() 
                    Spacer()
                    Spacer()
                }
                .foregroundColor(textcolor)
                
            }
            .edgesIgnoringSafeArea(.all)
            .sheet(isPresented: $show) {
                print("Sheet dismissed!")
                
            } content: {
                VStack{
                    HStack{
                        Spacer()
                        Button(action: dismissSheet){
                            Text("Done")
                            
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    Spacer()
                    VStack{
                        DatePicker(selection: $time_since, label: {
                            Text("Event date: ")})
                        .padding([.leading, .trailing, .bottom])
                        HStack{
                            Text("Event name: ")
                                .padding(.leading)
                            TextField("", text: $topic)
                            
                        }
                        ColorPicker("Text color:", selection: $textcolor)
                        ColorPicker("Widget text background color:", selection: $widgettextcolor)
                        ColorPicker("Widget background color:", selection: $widgetbgcolor)
                        /*
                         Picker(selection: $fontChoice, label: Text("Font Weight")) {
                         ForEach(fontOptions, id: \.self){
                         Text($0)
                         }
                         }
                         .pickerStyle(.segmented)*/
                        Toggle(isOn: $useBackgroundToggle) {
                            Text("Enable Background")
                        }
                        .onChange(of: useBackgroundToggle){newValue in
                            if !useBackgroundToggle{
                                
                                image = UIImage()
                                useBackground = false
                                realImage = false
                            } else if useBackgroundToggle{
                                do{ image = loadImageFromDiskWith(fileName:  "\(uuid).png") ?? UIImage()
                                } catch{
                                    image = UIImage(color: .systemBackground, size: CGSize(width: 10000, height: 10000))!
                                }
                                
                            }
                        }
                        if useBackgroundToggle{
                            HStack{
                                Button(action: {colorBG(color: .red)}){
                                    RoundedRectangle(cornerRadius: 60)
                                        .foregroundColor(.red)
                                }
                                Button(action: {colorBG(color: .cyan)}){
                                    RoundedRectangle(cornerRadius: 60)
                                        .foregroundColor(.cyan)
                                }
                                Button(action: {colorBG(color: .green)}){
                                    RoundedRectangle(cornerRadius: 60)
                                        .foregroundColor(.green)
                                }
                                ZStack{
                                    RoundedRectangle(cornerRadius: 60)
                                        .foregroundColor(bgcolor)
                                    HStack{
                                        
                                        ColorPicker(selection: $bgcolor){
                                            
                                        }
                                        .onChange(of:bgcolor) {newvalue in
                                            useBackground = true
                                            colorBG(color: UIColor(bgcolor))
                                        }
                                        .labelsHidden()
                                        .multilineTextAlignment(.leading)
                                        
                                    }
                                    
                                }
                                
                                
                            }
                            
                            .frame(height: UIScreen.main.bounds.width*0.2)
                            
                            Button(action: presentPicker){
                                Text("Choose Image")
                            }
                            
                            .sheet(isPresented: $showPicker) {
                                if (self.currentSheet == .imagePick) {
                                    ImagePickerView(croppingStyle: self.croppingStyle, sourceType: .photoLibrary, onCanceled: {
                                        // on cancel
                                    }) { (image) in
                                        guard let image = image else {
                                            return
                                        }
                                        
                                        self.originalImage = image
                                        DispatchQueue.main.async {
                                            self.currentSheet = .imageCrop
                                            self.showPicker = true
                                        }
                                    }
                                } else if (self.currentSheet == .imageCrop) {
                                    ImageCropView(croppingStyle: self.croppingStyle, originalImage: self.originalImage!, onCanceled: {
                                        // on cancel
                                        self.currentSheet = .imagePick
                                    }) { (image, cropRect, angle) in
                                        // on success
                                        self.image = image
                                        saveImage(imageName: "\(uuid).png", image: self.image)
                                        useBackground = true
                                        self.currentSheet = .imagePick
                                        realImage = true
                                        
                                    }
                                    
                                }
                                
                            }
                        }
                    }
                    .padding([.top, .leading, .trailing])
                    
                    Spacer()
                    Spacer()
                }
                
                Spacer()
            }
            .interactiveDismissDisabled(true)
            
            .onAppear(){
                dataModel = [getItem(with: uuid)]
                isNew = fix()
                topic = setTopic()
                time_since = setDate()
                useBackground = setBg()
                useBackgroundToggle = setBgToggle()
                
                if useBackgroundToggle && useBackground{
                    image = loadImageFromDiskWith(fileName:  "\(uuid).png")!
                }
                textcolor = setTextColor()
                realImage = setStatus()
                widgettextcolor = setWidgetTextColor()
                widgetbgcolor = setWidgetBGColor()
                bgcolor = setBGColor()
                isNew = false
                
            }
            
            .background(Image(uiImage: image).resizable().scaledToFill().edgesIgnoringSafeArea(.all).frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: showSheet){
                    Label("change date", systemImage: "gear")
                }
            }
            
        }
    }
    private func addItem(date: Date, topic: String, background: Bool, bgtoggle: Bool, realImage: Bool, bgcolor: Int, textColor: Int, widgetBgColor: Int, widgetTextColor: Int, firstLaunch: Bool) {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.date1970 = date
            newItem.topic = topic
            newItem.background = background
            newItem.backgroundtoggle = bgtoggle
            newItem.realimage = realImage
            newItem.bgcolor = Int64(bgcolor)
            newItem.textColor = Int64(textColor)
            newItem.widgetBgColor = Int64(widgetBgColor)
            newItem.widgetTextColor = Int64(widgetTextColor)
            newItem.firstLaunch = firstLaunch
            newItem.uuid = UUID()
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
    private func deleteItems() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try viewContext.fetch(fetchRequest)
                for object in results {
                    guard let objectData = object as? NSManagedObject else {continue}
                    viewContext.delete(objectData)
                }
            } catch let error {
                print("Detele all data in \(items) error :", error)
            }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(id: 5, uuid: UUID()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
