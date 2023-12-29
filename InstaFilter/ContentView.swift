//
//  ContentView.swift
//  InstaFilter
//
//  Created by Henrieke Baunack on 12/25/23.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var currentFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        NavigationStack{
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem){
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("Mo picture available", systemImage: "photo.badge.plus", description: Text("Tap to upload photo"))
                    }
                }
                .onChange(of: selectedItem, loadImage)
                // so that the whole view is not colored blue
                .buttonStyle(.plain)
                Spacer()
                HStack{
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity, applyProcessing)
                }
                HStack {
                    Button("Change Filter", action: changeFilter)
                    Spacer()
                    
                    //sharing
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("InstaFilter")
        }
    }
    
    func changeFilter() {
        // some code
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
        guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        currentFilter.intensity = Float(filterIntensity)
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        guard let CGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: CGImage)
        processedImage = Image(uiImage: uiImage)
    }
}

#Preview {
    ContentView()
}
