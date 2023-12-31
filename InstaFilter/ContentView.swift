//
//  ContentView.swift
//  InstaFilter
//
//  Created by Henrieke Baunack on 12/25/23.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var radiusFilter = 10.0
    @State private var scaleFilter = 10.0
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    
    var filterSelectionDisabled: Bool {
        if processedImage != nil {
            return false
        }
        else {
            return true
        }
    }
    
    var radiusSliderDisabled: Bool {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputRadiusKey) && processedImage != nil {
            return false
        }
        return true
    }
    
    var scaleSliderDisabled: Bool {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputScaleKey) && processedImage != nil {
            return false
        }
        return true
    }
    
    var intensitySliderDisabled: Bool {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) && processedImage != nil {
            return false
        }
        return true
    }
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
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
                    Slider(value: $filterIntensity,  in: 0.0...1.0)
                        .onChange(of: filterIntensity, applyProcessing)
                        .disabled(intensitySliderDisabled)
                }
                HStack{
                    Text("Scale")
                    Slider(value: $scaleFilter, in: 0.0...250.0)
                        .onChange(of: scaleFilter, applyProcessing)
                        .disabled(scaleSliderDisabled)
                }
                HStack{
                    Text("Radius")
                    Slider(value: $radiusFilter,  in: 0.0...100.0)
                        .onChange(of: radiusFilter, applyProcessing)
                        .disabled(radiusSliderDisabled)
                }
                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(filterSelectionDisabled)
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("InstaPreview", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("InstaFilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                // adding various filters
                Button("Crystalize"){ setFilter(CIFilter.crystallize())}
                Button("Edges"){ setFilter(CIFilter.edges())}
                Button("Gaussian Blur"){ setFilter(CIFilter.gaussianBlur())}
                Button("Pixellate"){ setFilter(CIFilter.pixellate())}
                Button("Sepia Tone"){ setFilter(CIFilter.sepiaTone())}
                Button("Unsharp Mask"){ setFilter(CIFilter.unsharpMask())}
                Button("Vignette"){ setFilter(CIFilter.vignette())}
                Button("MotionBlur"){ setFilter(CIFilter.motionBlur())}
                Button("Vibvrance"){ setFilter(CIFilter.vibrance())}
                Button("Bloom"){ setFilter(CIFilter.bloom())}
                Button("Cancel", role: .cancel){}
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
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
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputIntensityKey)
        }
        
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(radiusFilter, forKey: kCIInputRadiusKey)
        }
        
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(scaleFilter * 10, forKey: kCIInputScaleKey)
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        guard let CGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: CGImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    
    @MainActor func setFilter( _ filter: CIFilter){
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount >= 20 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}
