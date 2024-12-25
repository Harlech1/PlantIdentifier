import SwiftUI
import MarkdownUI

struct LoadingView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var imageBase64: String?
    @State private var apiResponse: String = ""
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main content
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Analyzing your plant...")
                        .font(.headline)
                    
                    Text("This might take a moment")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    
                    Button("Try Again") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    ScrollView {
                        Markdown(apiResponse)
                            .padding()
                    }
                    
                    Button("Take Another Photo") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 48) // Add top padding to push content down
            .padding() // Regular padding for other edges
            
            // Dismiss button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 12)
            .padding(.trailing)
        }
        .onAppear {
            if let base64Image = imageBase64 {
                analyzeImage(base64Image: base64Image)
            }
        }
    }
    
    func analyzeImage(base64Image: String) {
        let apiKey = "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"
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "What plant is this? Give me detailed information about this plant. Include its scientific name, common names, and basic care instructions. Keep it concise."
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
            "max_tokens": 500
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.error = "Failed to create request"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self.apiResponse = content
                    } else {
                        self.error = "Invalid response format"
                    }
                } catch {
                    self.error = "Failed to parse response"
                }
            }
        }.resume()
    }
} 
