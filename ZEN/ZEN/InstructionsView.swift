//
//  InstructionsView.swift
//  ZEN
//
//  Created by Emile Billeh on 24/02/2025.
//

import SwiftUI

struct InstructionsView: View {
    
    @AppStorage("showingInstructions") private var showingInstructions: Bool = true
    
    var body: some View {
        VStack (alignment: .leading) {
            Button {
                withAnimation(.easeInOut(duration: 0.1)) { // ✅ Smooth animation
                    showingInstructions.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(showingInstructions ? 0 : -90)) // ✅ Rotate arrow
                        .animation(.easeInOut(duration: 0.2), value: showingInstructions) // ✅ Animate rotation
                    
                    Text(showingInstructions ? "Hide instructions" : "Show instructions")
                        .font(.subheadline)
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            
            if showingInstructions {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "cursorarrow.and.square.on.square.dashed")
                        Text("Drag and drop the item above into the desired folder")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search for a desired folder in the top right corner")
                            .font(.subheadline)
                    }
                    HStack {
                        Image(systemName: "cursorarrow.click.2")
                        Text("Right click on a folder below to view its current contents")
                            .font(.subheadline)
                    }
                }
                .padding(.leading)
                .transition(.opacity.combined(with: .move(edge: .top))) // ✅ Fade & slide in/out
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

#Preview {
    InstructionsView()
}
