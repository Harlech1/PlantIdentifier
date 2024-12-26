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
           let compressedData = uiImage.jpegData(compressionQuality: 0.3) {
            self.imageData = compressedData
        } else {
            self.imageData = imageData
        }
    }
}

struct CollectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedPlant: PlantEntity?
    
    // Update FetchRequest to include the search filter
    var plantRequest: FetchRequest<PlantEntity>
    private var plants: FetchedResults<PlantEntity> { plantRequest.wrappedValue }
    
    init() {
        let request: NSFetchRequest<PlantEntity> = PlantEntity.fetchRequest()
        // Sort by date in descending order (newest first), then by common name
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PlantEntity.dateAdded, ascending: false),
            NSSortDescriptor(keyPath: \PlantEntity.commonName, ascending: true)
        ]
        self.plantRequest = FetchRequest(fetchRequest: request)
    }
    
    // Filtered plants based on search text
    private var filteredPlants: [PlantEntity] {
        if searchText.isEmpty {
            return Array(plants)
        }
        return plants.filter {
            ($0.commonName ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.scientificName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    @State private var showingAddSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    
    let columns = [GridItem(.flexible())]
    
    // Add delete function
    private func deletePlant(_ plant: PlantEntity) {
        viewContext.delete(plant)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting plant: \(error)")
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredPlants) { plant in
                    PlantCard(plant: plant)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            selectedPlant = plant
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deletePlant(plant)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Garden")
            .navigationDestination(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
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
            .toolbar() {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Plant")
                        }
                        .foregroundStyle(.green)
                    }
                    .padding()
                }
            }
            .onChange(of: showingCamera) { isShowing in
                if isShowing {
                    showingAddSheet = false
                }
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
                               let compressedData = uiImage.jpegData(compressionQuality: 0.3) {
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
                           let compressedData = uiImage.jpegData(compressionQuality: 0.3) {
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
        HStack(alignment: .center, spacing: 12) {
            if let imageData = plant.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.leading, 12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName ?? "Undefined")
                    .font(.headline)
                    .lineLimit(2)
                
                Text(plant.scientificName ?? "Undefined")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                if let date = plant.dateAdded {
                    HStack {
                        Spacer()
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            Spacer()
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    CollectionView()
}
