import SwiftUI
import MapKit
import TPackage

struct PlantDetailView: View {
    let plant: PlantEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var region: MKCoordinateRegion
    @State private var showingShareSheet = false
    @State private var showingMapSheet = false
    @State private var isFavorite: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingWateringSheet = false
    @State private var showPaywall = false
    @EnvironmentObject var premiumManager: TKPremiumManager
    
    private var mapsURL: URL? {
        let latitude = plant.latitude
        let longitude = plant.longitude
        return URL(string: "http://maps.apple.com/?ll=\(latitude),\(longitude)")
    }
    
    private var shareItems: [Any] {
        var items: [Any] = []
        
        // Add image if available
        if let imageData = plant.imageData,
           let uiImage = UIImage(data: imageData) {
            items.append(uiImage)
        }
        
        // Create text content
        var text = """
        Check out what I've found with Herbi!
        Common Name: \(plant.commonName ?? "Unknown")
        Scientific Name: \(plant.scientificName ?? "Unknown")
        """
        
        if let locationName = plant.locationName {
            text += "\nLocation: \(locationName)"
        }
        
        if let mapsURL = mapsURL {
            text += "\nView on Apple Maps: \(mapsURL.absoluteString)"
        }
        
        if let date = plant.dateAdded {
            text += "\nAdded: \(date.formatted(date: .long, time: .shortened))"
        }

        text += "\nInstall Herbi today! https://apps.apple.com/us/app/herbi-ai-plant-identifier/id6739781021"

        items.append(text)
        
        return items
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: plant.latitude,
            longitude: plant.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = plant.commonName
        mapItem.openInMaps()
    }
    
    private func deletePlant() {
        viewContext.delete(plant)
        try? viewContext.save()
        dismiss()
    }
    
    init(plant: PlantEntity) {
        self.plant = plant
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: plant.latitude,
                longitude: plant.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        _isFavorite = State(initialValue: plant.isFavorite)
    }
    
    var body: some View {
        List {
            Section(header: HStack {
                Image(systemName: "laurel.leading")
                    .symbolRenderingMode(.multicolor)
                Text("Plant Information")
                Image(systemName: "laurel.trailing")
                    .symbolRenderingMode(.multicolor)
            },footer: Text("Herbi can make mistakes. Verify important information.")) {
                HStack() {
                    Label {
                        Text("Common Name")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Text(plant.commonName ?? "Unknown")
                        .bold()
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack() {
                    Label {
                        Text("Scientific Name")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "text.book.closed.fill")
                            .foregroundStyle(.brown)
                    }
                    Spacer()
                    Text(plant.scientificName ?? "Unknown")
                        .italic()
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack() {
                    Label {
                        Text("Address")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "map.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(plant.locationName ?? "Unknown")
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack() {
                    Label {
                        Text("Toxicity")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(plant.isPoisonous?.lowercased() == "yes" ? .red : .orange)
                    }
                    Spacer()
                    Text(plant.isPoisonous ?? "Unknown")
                        .foregroundColor(plant.isPoisonous?.lowercased() == "yes" ? .red : .primary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let symbolism = plant.symbolism {
                    HStack() {
                        Label {
                            Text("Symbolism")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                        }
                        Spacer()
                        Text(symbolism)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .blur(radius: premiumManager.isPremium ? 0 : 5)

                    }
                    .onTapGesture {
                        if !premiumManager.isPremium {
                            showPaywall = true
                        }
                    }
                }
                
                if let giftTo = plant.giftTo {
                    HStack() {
                        Label {
                            Text("Gift To")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(.purple)
                        }
                        Spacer()
                        Text(giftTo)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .blur(radius: premiumManager.isPremium ? 0 : 5)
                    }
                    .onTapGesture {
                        if !premiumManager.isPremium {
                            showPaywall = true
                        }
                    }
                }

                if let bloomingPeriod = plant.bloomingPeriod {
                    HStack {
                        Label {
                            Text("Blooming Period")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "sunrise.fill")
                                .symbolRenderingMode(.multicolor)
                        }
                        Spacer()
                        Text(bloomingPeriod)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let nativeRegion = plant.nativeRegion {
                    HStack {
                        Label {
                            Text("Native Region")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text(nativeRegion)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Section(header: HStack {
                Image(systemName: "stethoscope")
                    .symbolRenderingMode(.multicolor)
                Text("Care")
            }) {
                HStack {
                    Label {
                        Text("Last Watered")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(plant.lastWatered?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
                        .foregroundStyle(plant.lastWatered == nil ? .secondary : .primary)
                }

                if plant.waterReminder {
                    HStack {
                        Label {
                            Text("Next Watering")
                            .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        if let nextWatering = plant.lastWatered?.addingTimeInterval(Double(plant.wateringInterval) * 24 * 60 * 60) {
                            Text(nextWatering.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }

                Button {
                    if premiumManager.isPremium {
                        showingWateringSheet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Set Watering Schedule", systemImage: "timer")
                }
            }

            if let story = plant.story, story.lowercased() != "none" {
                Section(header: HStack {
                    Image(systemName: "book.pages")
                        .symbolRenderingMode(.hierarchical)
                    Text("Story & Mythology")
                }) {
                    Text(story)
                        .padding(4)
                        .blur(radius: premiumManager.isPremium ? 0 : 5)
                        .onTapGesture {
                            if !premiumManager.isPremium {
                                showPaywall = true
                            }
                        }
                }
            }
            
            if let date = plant.dateAdded {
                Section("Added") {
                    HStack {
                        Label {
                            Text("Date")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text(date.formatted(date: .long, time: .shortened))
                    }
                }
            }
            

        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(plant.commonName ?? "Plant Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        openInMaps()
                    } label: {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                    }
                    
                    Menu {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share to Friends", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                        
                        Button {
                            showingMapSheet = true
                        } label: {
                            Label("See on Map", systemImage: "map")
                        }
                        .tint(.green)
                        
                        Button {
                            withAnimation(.spring()) {
                                isFavorite.toggle()
                                plant.isFavorite = isFavorite
                                try? viewContext.save()
                            }
                        } label: {
                            Label(
                                isFavorite ? "Remove from Garden" : "Add to Garden",
                                systemImage: isFavorite ? "heart.fill" : "heart"
                            )
                        }
                        .tint(isFavorite ? .red : .pink)
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Plant", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .alert("Delete Plant", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePlant()
            }
        } message: {
            Text("Are you sure you want to delete this plant? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showingMapSheet) {
            NavigationStack {
                MapDetailView(plant: plant)
            }
        }
        .sheet(isPresented: $showingWateringSheet) {
            WateringScheduleView(plant: plant)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            CustomPaywallView(secondDelayOpen: true)
                .paywallFooter(condensed: true)
                .onPurchaseCompleted { customerInfo in
                    Task {
                        await premiumManager.checkPremiumStatus()
                        if premiumManager.isPremium {
                            showPaywall = false
                        }
                    }
                }
                .onRestoreCompleted { customerInfo in
                    Task {
                        await premiumManager.checkPremiumStatus()
                        if premiumManager.isPremium {
                            showPaywall = false
                        }
                    }
                }
                .interactiveDismissDisabled()
        }
    }
}

struct MapDetailView: View {
    let plant: PlantEntity
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: plant.latitude,
                longitude: plant.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))) {
            Marker(plant.commonName ?? "Plant", coordinate: CLLocationCoordinate2D(
                latitude: plant.latitude,
                longitude: plant.longitude
            ))
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct WateringScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    let plant: PlantEntity
    
    @State private var waterReminder: Bool
    @State private var wateringInterval: Int
    @State private var lastWatered: Date
    
    init(plant: PlantEntity) {
        self.plant = plant
        _waterReminder = State(initialValue: plant.waterReminder)
        _wateringInterval = State(initialValue: max(Int(plant.wateringInterval), 1))
        _lastWatered = State(initialValue: plant.lastWatered ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Enable Watering Reminders", isOn: $waterReminder)
                
                if waterReminder {
                    Stepper(
                        "Water every \(wateringInterval) day\(wateringInterval == 1 ? "" : "s")", 
                        value: $wateringInterval,
                        in: 1...30,
                        step: 1
                    )
                    
                    DatePicker(
                        "Last Watered",
                        selection: $lastWatered,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("Watering Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWateringSchedule()
                    }
                }
            }
        }
        .presentationDetents([.height(250)])
        .presentationCornerRadius(30)
    }
    
    private func saveWateringSchedule() {
        plant.waterReminder = waterReminder
        plant.wateringInterval = Int16(wateringInterval)
        plant.lastWatered = lastWatered
        
        if waterReminder {
            scheduleWateringNotification()
        } else {
            cancelWateringNotification()
        }
        
        try? viewContext.save()
        dismiss()
    }
    
    private func scheduleWateringNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Water Your \(plant.commonName ?? "Plant")!"
        content.body = "Your plant needs watering today."
        content.sound = .default
        
        let nextWatering = lastWatered.addingTimeInterval(Double(wateringInterval) * 24 * 60 * 60)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: nextWatering)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "water-reminder-\(plant.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelWateringNotification() {
        if let id = plant.id?.uuidString {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["water-reminder-\(id)"]
            )
        }
    }
}

// ShareSheet wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
