//
//  CollectionView.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 24.12.2024.
//

import SwiftUI
import PhotosUI
import CoreData

struct Plant: Identifiable, Codable {
    var id: UUID
    let commonName: String
    let scientificName: String
    let imageData: Data

    init(id: UUID = UUID(), commonName: String, scientificName: String, imageData: Data) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        if let uiImage = UIImage(data: imageData),
           let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
            self.imageData = compressedData
        } else {
            self.imageData = imageData
        }
    }
}

struct CollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var sunBounce = false
    @State private var selectedPlant: PlantEntity?

    var plantRequest: FetchRequest<PlantEntity>
    private var plants: FetchedResults<PlantEntity> { plantRequest.wrappedValue }

    init() {
        let request: NSFetchRequest<PlantEntity> = PlantEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PlantEntity.dateAdded, ascending: false),
            NSSortDescriptor(keyPath: \PlantEntity.commonName, ascending: true)
        ]
        self.plantRequest = FetchRequest(fetchRequest: request)
    }

    private var filteredPlants: [PlantEntity] {
        let filtered = plants.filter { plant in
            let matchesSearch = searchText.isEmpty ||
            (plant.commonName ?? "").localizedCaseInsensitiveContains(searchText) ||
            (plant.scientificName ?? "").localizedCaseInsensitiveContains(searchText)
            return matchesSearch && (!showFavoritesOnly || plant.isFavorite)
        }

        if showFavoritesOnly {
            return filtered.sorted { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() }
        } else {
            return filtered
        }
    }

    @State private var showingAddSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    let columns = [GridItem(.flexible())]

    private func deletePlant(_ plant: PlantEntity) {
        viewContext.delete(plant)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting plant: \(error)")
        }
    }

    @State private var isBouncingRainbow = false
    @State private var isBouncingRain = false
    @State private var rainbowTimer: Timer?
    @State private var rainTimer: Timer?

    var body: some View {
        NavigationStack {
            Group {
                if filteredPlants.isEmpty {
                    if searchText.isEmpty && !showFavoritesOnly {
                        ContentUnavailableView(
                            "Your Garden Awaits",
                            systemImage: "rainbow",
                            description: Text("Plant your first memory by adding a new discovery to your garden.")
                        )
                        .symbolRenderingMode(.multicolor)
                        .symbolEffect(.bounce, value: isBouncingRainbow)
                        .onAppear {
                            rainbowTimer?.invalidate()
                            rainbowTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                                isBouncingRainbow.toggle()
                            }
                        }
                        .onDisappear {
                            rainbowTimer?.invalidate()
                            rainbowTimer = nil
                        }
                    } else {
                        ContentUnavailableView(
                            "No Plants Found",
                            systemImage: "cloud.rain.fill",
                            description: Text(showFavoritesOnly ?
                                "Your garden of favorites is waiting to bloom." :
                                "Let's explore a different path in your garden."
                            )
                        )
                        .symbolEffect(.bounce, value: isBouncingRain)
                        .onAppear {
                            rainTimer?.invalidate()
                            rainTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                                isBouncingRain.toggle()
                            }
                        }
                        .onDisappear {
                            rainTimer?.invalidate()
                            rainTimer = nil
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredPlants) { plant in
                                PlantCard(plant: plant)
                                    .onTapGesture {
                                        selectedPlant = plant
                                    }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, 16)
            .navigationDestination(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
            .listStyle(.plain)
            .navigationTitle("Garden")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            sunBounce.toggle()
                            showFavoritesOnly.toggle()
                        } label: {
                            Image(systemName: showFavoritesOnly ? "sun.max.fill" : "sun.max")
                                .foregroundStyle(.yellow)
                                .symbolEffect(.bounce, value: sunBounce)
                        }

                        Button(action: {
                            showingAddSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Plant")
                            }
                            .foregroundStyle(.green)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Button(action: {
                            showingAddSheet = false
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                        }

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Gallery")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.height(150)])
            }
            .sheet(isPresented: $showingImagePicker) {
                if let imageData = selectedImageData {
                    AddPlantView(initialImageData: imageData)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(
                    capturedImageBase64: Binding(
                        get: { nil },
                        set: { newValue in
                            if let newValue = newValue,
                               let imageData = Data(base64Encoded: newValue),
                               let uiImage = UIImage(data: imageData),
                               let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                                selectedImageData = compressedData
                                showingCamera = false
                                showingImagePicker = true
                            }
                        }
                    ),
                    showingCamera: $showingCamera,
                    showingLoadingScreen: .constant(false)
                )
            }
            .onChange(of: selectedItem) { newItem in
                if let item = newItem {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data),
                           let compressedData = uiImage.jpegData(compressionQuality: 0.7) {
                            selectedImageData = compressedData
                            selectedItem = nil
                            showingAddSheet = false
                            showingImagePicker = true
                        }
                    }
                }
            }
        }
        .refreshable {
            print("hi")
        }
        .searchable(
            text: $searchText,
            prompt: "Search plants..."
        )
    }
}

struct PlantCard: View {
    let plant: PlantEntity

    var body: some View {
        HStack(spacing: 16) {
            if let imageData = plant.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName ?? "Undefined")
                    .font(.headline)
                    .lineLimit(1)

                Text(plant.scientificName ?? "Undefined")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let date = plant.dateAdded {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                            .font(.system(size: 12))

                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    CollectionView()
}
