import SwiftUI
import MapKit

struct PlantDetailView: View {
    let plant: PlantEntity
    @State private var region: MKCoordinateRegion
    @State private var showingShareSheet = false
    
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
        Common Name: \(plant.commonName ?? "Unknown")
        Scientific Name: \(plant.scientificName ?? "Unknown")
        """
        
        if let locationName = plant.locationName {
            text += "\nLocation: \(locationName)"
        }
        
        if let mapsURL = mapsURL {
            text += "\nView on Maps: \(mapsURL.absoluteString)"
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
    
    init(plant: PlantEntity) {
        self.plant = plant
        let coordinate = CLLocationCoordinate2D(
            latitude: plant.latitude,
            longitude: plant.longitude
        )
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        List {
            Section {
                if let imageData = plant.imageData,
                   let uiImage = UIImage(data: imageData) {
                    HStack {
                        Spacer()
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .listRowInsets(EdgeInsets())
                        Spacer()
                    }

                }
            }
            .listRowBackground(Color.clear)
            
            Section("Plant Information") {
                HStack {
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
                }
                
                HStack {
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
                }

                HStack {
                    Label {
                        Text("Address")
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "map.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(plant.locationName ?? "Unknown")
                }
            }
            
            // Location Section
            if let locationName = plant.locationName {
                Section("Location") {
                    VStack(alignment: .leading, spacing: 8) {
                        Map(coordinateRegion: $region,
                            annotationItems: [plant]) { plant in
                            MapAnnotation(
                                coordinate: CLLocationCoordinate2D(
                                    latitude: plant.latitude,
                                    longitude: plant.longitude
                                )
                            ) {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 32, height: 32)
                                    )
                            }
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .listRowBackground(Color.clear)
            }
            
            // Date Section
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
                        Image(systemName: "map")
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
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
