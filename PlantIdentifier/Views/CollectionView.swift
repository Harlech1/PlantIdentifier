//
//  CollectionView.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 24.12.2024.
//

import SwiftUI
import PhotosUI
import CoreData
import TPackage

struct CollectionView: View {
    @EnvironmentObject var premiumManager: TKPremiumManager
    @StateObject private var ratingManager = RatingManager.shared

    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var sunBounce = false

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("launchCount") private var launchCount: Int = 0
    @State private var hasShownInitialPaywall = false
    @State private var showPaywall = false
    @State private var showOnboarding = false
    @State private var showSpecialOffer = false

    @State private var showingAddSheet = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    let columns = [GridItem(.flexible())]

    @State private var isBouncingRainbow = false
    @State private var isBouncingRain = false
    @State private var rainbowTimer: Timer?
    @State private var rainTimer: Timer?

    @Environment(\.managedObjectContext) private var viewContext
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
                               let compressedData = uiImage.compressed() {
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
                           let compressedData = uiImage.compressed() {
                            selectedImageData = compressedData
                            selectedItem = nil
                            showingAddSheet = false
                            showingImagePicker = true
                        }
                    }
                }
            }
        }
        .task {
            await premiumManager.checkPremiumStatus()
            
            if !hasSeenOnboarding {
                showOnboarding = true
            } else if !hasShownInitialPaywall && !premiumManager.isPremium {
                showPaywall = true
                hasShownInitialPaywall = true
            }
            
            if launchCount == 3 {
                await ratingManager.requestReview()
            }

            launchCount += 1
        }
        .fullScreenCover(isPresented: $showSpecialOffer) {
            SpecialOfferView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
                .onDisappear {
                    hasSeenOnboarding = true
                    if !premiumManager.isPremium && !hasShownInitialPaywall {
                        showPaywall = true
                        hasShownInitialPaywall = true
                    }
                }
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
                .onDisappear {
                    if !premiumManager.isPremium && !showSpecialOffer && launchCount % 2 == 1 {
                        showSpecialOffer = true
                    }
                }
                .interactiveDismissDisabled()
        }
    }

    private func deletePlant(_ plant: PlantEntity) {
        viewContext.delete(plant)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting plant: \(error)")
        }
    }
}

#Preview {
    CollectionView()
}
