//
//  AddPlantView.swift
//  PlantIdentifier
//
//  Created by Türker Kızılcık on 25.12.2024.
//

import SwiftUI

struct AddPlantView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @State private var isAnalyzing = false
    @State private var commonName = ""
    @State private var scientificName = ""
    let initialImageData: Data

    private func savePlant() {
        let newPlant = PlantEntity(context: viewContext)
        newPlant.id = UUID()
        newPlant.commonName = commonName
        newPlant.scientificName = scientificName
        newPlant.imageData = initialImageData
        newPlant.dateAdded = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving plant: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let uiImage = UIImage(data: initialImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 5)
                    }

                    if isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Analyzing plant...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    } else if !commonName.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Plant Information")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Common Name:")
                                        .foregroundColor(.secondary)
                                    Text(commonName)
                                        .bold()
                                }

                                HStack {
                                    Text("Scientific Name:")
                                        .foregroundColor(.secondary)
                                    Text(scientificName)
                                        .italic()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
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
            .background(Color(.systemGroupedBackground))
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
