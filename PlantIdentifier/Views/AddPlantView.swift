//
//  AddPlantView.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 25.12.2024.
//

import SwiftUI
import CoreLocation
import MapKit
import TPackage

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
    @State private var isPoisonous: String = ""
    @State private var symbolism = ""
    @State private var giftTo = ""
    @State private var story = ""
    @State private var bloomingPeriod = ""
    @State private var nativeRegion = ""
    @StateObject private var locationManager = LocationManager()
    @State private var currentLocationName: String = ""
    @State private var identificationFailed = false
    @EnvironmentObject var premiumManager: TKPremiumManager

    private func savePlant() {
        let newPlant = PlantEntity(context: viewContext)
        newPlant.id = UUID()
        newPlant.commonName = commonName
        newPlant.scientificName = scientificName
        newPlant.imageData = initialImageData
        newPlant.dateAdded = Date()
        newPlant.isPoisonous = isPoisonous
        newPlant.symbolism = symbolism
        newPlant.giftTo = giftTo
        newPlant.story = story
        newPlant.bloomingPeriod = bloomingPeriod
        newPlant.nativeRegion = nativeRegion

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
            Group {
                if identificationFailed {
                    ContentUnavailableView(
                        "Unable to Identify Plant",
                        systemImage: "leaf.circle.fill",
                        description: Text("We couldn't identify this plant. Please try again with a clearer photo.")
                    )
                    .foregroundStyle(.red)
                } else {
                    List {
                        Section {
                            if let uiImage = UIImage(data: initialImageData) {
                                GeometryReader { geometry in
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                }
                                .frame(height: 200)
                                .listRowInsets(EdgeInsets())
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
                                HStack() {
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
                                    Text(scientificName)
                                        .italic()
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                HStack() {
                                    Label {
                                        Text("Toxicity")
                                            .foregroundColor(.secondary)
                                    } icon: {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(isPoisonous.lowercased() == "yes" ? .red : .orange)
                                    }
                                    Spacer()
                                    Text(isPoisonous.isEmpty ? "Unknown" : isPoisonous)
                                        .foregroundColor(isPoisonous.lowercased() == "yes" ? .red : .primary)
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
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
                                            .multilineTextAlignment(.trailing)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                HStack() {
                                    Label {
                                        Text("Added")
                                            .foregroundColor(.secondary)
                                    } icon: {
                                        Image(systemName: "calendar")
                                            .foregroundStyle(.blue)
                                    }
                                    Spacer()
                                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                                        .multilineTextAlignment(.trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if !symbolism.isEmpty {
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
                                            .blur(radius: premiumManager.isPremium ? 0 : 3)

                                    }
                                }

                                if !giftTo.isEmpty {
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
                                            .blur(radius: premiumManager.isPremium ? 0 : 3)

                                    }
                                }

                                if !bloomingPeriod.isEmpty {
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

                                if !nativeRegion.isEmpty {
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
                            if !story.isEmpty && story.lowercased() != "none" {
                                Section(header: Text("Story & Mythology")) {
                                    Text(story)
                                        .padding(4)
                                        .blur(radius: premiumManager.isPremium ? 0 : 3)
                                }
                            }
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
                    .disabled(commonName.isEmpty || identificationFailed)
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
                if let location = locationManager.location {
                    await getCurrentLocationName(from: location)
                }
                await analyzePlant(imageData: initialImageData)
            }
        }
    }

    private func getCurrentLocationName(from location: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            if let placemark = try await geocoder.reverseGeocodeLocation(location).first {
                let locationComponents = [
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }
                currentLocationName = locationComponents.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error)")
        }
    }

    func analyzePlant(imageData: Data) async {
        isAnalyzing = true
        identificationFailed = false
        
        let base64Image = imageData.base64EncodedString()
        
        // Prepare the request
        guard let url = URL(string: "https://api.turkerkizilcik.com/plant-identify.php") else {
            print("Invalid URL")
            isAnalyzing = false
            return
        }
        
        let parameters = [
            "image": base64Image,
            "location": currentLocationName
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let success = json["success"] as? Bool, success {
                    if let result = json["data"] as? [String: String] {
                        commonName = result["common_name"] ?? ""
                        scientificName = result["scientific_name"] ?? ""
                        isPoisonous = result["poisonous"] ?? ""
                        bloomingPeriod = result["blooming_period"] ?? ""
                        nativeRegion = result["native_region"] ?? ""
                        symbolism = result["symbolism"] ?? ""
                        giftTo = result["gift_to"] ?? ""
                        story = result["story"] ?? ""
                    }
                } else {
                    identificationFailed = true
                }
            }
        } catch {
            print("Error: \(error)")
            identificationFailed = true
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
                                debounceTimer?.invalidate()
                                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    isDragging = false
                                    reverseGeocode(region.center)
                                }
                            }
                    }
                }

                if searchResults.isEmpty {
                    Circle()
                        .fill(isDragging ? .green.opacity(0.85) : .green)
                        .frame(width: 8, height: 8)

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
                    Button("Dismiss") {
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
