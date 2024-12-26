//
//  AddPlantView.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 25.12.2024.
//

import SwiftUI
import CoreLocation
import MapKit

struct AddPlantView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var isAnalyzing = false
    @State private var commonName = ""
    @State private var scientificName = ""
    @State private var locationName = ""
    @State private var showingLocationPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    let initialImageData: Data
    
    private func savePlant() {
        let newPlant = PlantEntity(context: viewContext)
        newPlant.id = UUID()
        newPlant.commonName = commonName
        newPlant.scientificName = scientificName
        newPlant.imageData = initialImageData
        newPlant.dateAdded = Date()
        
        if let coordinate = selectedCoordinate {
            newPlant.latitude = coordinate.latitude
            newPlant.longitude = coordinate.longitude
            newPlant.locationName = locationName
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving plant: \(error)")
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Image Section
                Section {
                    if let uiImage = UIImage(data: initialImageData) {
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

                if isAnalyzing {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Analyzing plant...")
                                .foregroundColor(.secondary)
                                .padding(.leading)
                        }
                    }
                }
                
                if !commonName.isEmpty {
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
                            Text(commonName)
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
                            Text(scientificName)
                                .italic()
                        }
                        
                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            HStack {
                                Label {
                                    Text("Location")
                                        .foregroundColor(.secondary)
                                } icon: {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.red)
                                }
                                Spacer()
                                Text(locationName.isEmpty ? "Select Location" : locationName)
                                    .foregroundColor(locationName.isEmpty ? .blue : .primary)
                            }
                        }
                        
                        HStack {
                            Label {
                                Text("Added")
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                            Text(Date().formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlant()
                    }
                    .disabled(commonName.isEmpty)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    locationName: $locationName,
                    selectedCoordinate: $selectedCoordinate
                )
            }
        }
        .onAppear {
            Task {
                await analyzePlant(imageData: initialImageData)
            }
        }
    }

    func analyzePlant(imageData: Data) async {
        isAnalyzing = true
        let apiKey = "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"
        let endpoint = "https://api.openai.com/v1/chat/completions"

        let base64Image = imageData.base64EncodedString()

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "What is this plant? Please provide ONLY the common name and scientific name in this format: 'common_name: NAME\nscientific_name: NAME'. Do not include any other text."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 100
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            isAnalyzing = false
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {

                // Parse the response
                let lines = content.components(separatedBy: "\n")
                for line in lines {
                    if line.lowercased().starts(with: "common_name:") {
                        commonName = line.replacingOccurrences(of: "common_name:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if line.lowercased().starts(with: "scientific_name:") {
                        scientificName = line.replacingOccurrences(of: "scientific_name:", with: "").trimmingCharacters(in: .whitespaces)
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }

        isAnalyzing = false
    }
}

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var locationName: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var hasInitialLocation = false
    @State private var isDragging = false
    @State private var debounceTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    TextField("Search location", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .onChange(of: searchText) { _ in
                            searchLocations()
                        }
                    
                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { item in
                            Button {
                                selectLocation(item)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "")
                                        .foregroundColor(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    } else {
                        Map(coordinateRegion: $region, showsUserLocation: true)
                            .onChange(of: region.center.latitude) { _ in
                                isDragging = true
                                // Cancel previous timer if it exists
                                debounceTimer?.invalidate()
                                // Create new timer
                                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    isDragging = false
                                    reverseGeocode(region.center)
                                }
                            }
                    }
                }
                
                // Center Pin
                if searchResults.isEmpty {
                    VStack {
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundColor(.red)
                            .opacity(isDragging ? 0.5 : 1.0)
                        
                        Circle()
                            .fill(.red)
                            .frame(width: 5, height: 5)
                            .shadow(radius: 2)
                    }
                    
                    VStack {
                        Spacer()
                        if !locationName.isEmpty {
                            Text(isDragging ? "Moving..." : locationName)
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedCoordinate = region.center
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationManager.startUpdatingLocation()
            }
            .onChange(of: locationManager.location) { newLocation in
                if let location = newLocation, !hasInitialLocation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                    hasInitialLocation = true
                }
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedCoordinate = item.placemark.coordinate
        let address = [
            item.placemark.thoroughfare,
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.country
        ].compactMap { $0 }.joined(separator: ", ")
        locationName = address
        region.center = item.placemark.coordinate
        searchResults.removeAll()
        searchText = ""
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                selectedCoordinate = coordinate
                let address = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                locationName = address
            }
        }
    }
    
    private func searchLocations() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        MKLocalSearch(request: request).start { response, error in
            guard let response = response else { return }
            searchResults = response.mapItems
        }
    }
}

// Add this class to manage location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.location = location
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}
