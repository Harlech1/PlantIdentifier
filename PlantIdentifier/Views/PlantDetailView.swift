import SwiftUI
import MapKit

struct PlantDetailView: View {
    let plant: PlantEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State private var region: MKCoordinateRegion
    @State private var showingShareSheet = false
    @State private var showingMapSheet = false
    @State private var isFavorite: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    
    private var mapsURL: URL? {
        let latitude = plant.latitude
        let longitude = plant.longitude
        // Create Apple Maps URL with coordinates
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
        Check out what I've found!
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
//            Section {
//                if let imageData = plant.imageData,
//                   let uiImage = UIImage(data: imageData) {
//                    GeometryReader { geometry in
//                        Image(uiImage: uiImage)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: geometry.size.width, height: 200)
//                            .clipShape(RoundedRectangle(cornerRadius: 16))
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
//                            )
//                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
//                    }
//                    .frame(height: 200)
//                    .listRowInsets(EdgeInsets())
//                }
//            }
//            .listRowBackground(Color.clear)
            
            Section("Plant Information") {
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

                if let hemisphere = plant.hemisphere {
                    HStack {
                        Label {
                            Text("Native Region")
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                        Text(hemisphere)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if let story = plant.story, story.lowercased() != "none" {
                Section(header: Text("Story & Mythology"), footer: Text("Herbi can make mistakes. Verify important information.")) {
                    Text(story)
                        .padding(4)
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
                        Image(systemName: "ellipsis.circle")
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

// ShareSheet wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
