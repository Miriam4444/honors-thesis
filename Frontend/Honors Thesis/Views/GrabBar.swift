//
//  GrabBar.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/27/26.
//the little bar on top of a floating panel (like the one on normal vision pro windows, but on top so it's easy to reach).
//look at it, pinch, and drag to move the panel.
//
//it's part of the SwiftUI panel (not a separate 3D object) because SwiftUI views in the
//panels reliably get your pinches. the drag is measured in the room's coordinates
//(.immersiveSpace), not the panel's, because the panel moves while you drag it and
//measuring against something that's moving makes it jitter.

#if os(visionOS)
import SwiftUI

struct GrabBar: View {
    //how far your hand has moved since the drag started, in meters, in room directions
    //(x = right, y = up, z = toward where you started facing)
    var onDrag: (SIMD3<Float>) -> Void
    var onEnd: () -> Void

    @Environment(\.physicalMetrics) private var physicalMetrics //converts points to real meters

    var body: some View {
        Capsule()
            .fill(.white.opacity(0.85))
            .frame(width: 110, height: 9)
            .frame(width: 220, height: 44) //much bigger invisible area so it's easy to grab
            .contentShape(Rectangle())
            .hoverEffect() //glows when you look at it
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .immersiveSpace)
                    .onChanged { value in
                        let t = value.translation3D
                        //SwiftUI's y points down, the room's y points up, so flip it
                        onDrag(SIMD3(meters(t.x), -meters(t.y), meters(t.z)))
                    }
                    .onEnded { _ in onEnd() }
            )
    }

    private func meters(_ points: Double) -> Float {
        Float(physicalMetrics.convert(CGFloat(points), to: .meters))
    }
}
#endif
