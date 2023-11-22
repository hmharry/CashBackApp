//
//  GetLookAroundScene.swift
//  LocalSearch
//
//  Created by Kai Tai Lau on 3/11/2023.
//

import SwiftUI
import MapKit

struct GetLookAroundScene: View {
    
    @State private var lookAroundScene: MKLookAroundScene?
    @Binding var mapItem: MKMapItem?
    @Binding var showDirection: Bool
    
    func getLookAroundScene() {
        if let mapItem {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(coordinate: mapItem.placemark.coordinate)
                lookAroundScene = try? await request.scene
            }
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                if lookAroundScene == nil {
                    ContentUnavailableView("No Look Around Scene Available", systemImage: "eye.slash")
                } else {
                    LookAroundPreview(scene: $lookAroundScene)
                        .overlay(alignment: .bottomTrailing) {
                            HStack {
                                VStack {
                                    Text("\(mapItem?.name ?? "")")
                                    Button {
                                        showDirection = true
                                    } label: {
                                        Label("Show Driving direction", systemImage: "car")
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                            }
                            .labelStyle(.iconOnly)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(10)
                        }
                        .cornerRadius(12)
                        .padding()
                }
            }
        }
        .onAppear {
            getLookAroundScene()
        }
        .onChange(of: mapItem) {
            getLookAroundScene()
        }
    }
}
