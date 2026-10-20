//
//  HeadFollower.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/20/26.
//keeps the floating panels in the same spot in your view, no matter where you walk or look.
//every frame it asks ARKit where your head is and glides the panels toward that spot.
//(it glides instead of snapping so the panels don't jitter with every tiny head movement)
//
//why not just AnchorEntity(.head)? stuff anchored straight to your head can be hard or
//impossible to tap, so instead the panels live in the room and chase your head.

#if os(visionOS)
import SwiftUI
import ARKit
import RealityKit
import QuartzCore

final class HeadFollower {
    private let session = ARKitSession()
    private var worldTracking: WorldTrackingProvider?
    private var subscription: EventSubscription?
    private var hasPlaced = false

    //where your head was last frame (room coordinates), so the diagram can turn to face you
    private(set) var lastHeadPosition: SIMD3<Float>?

    //bigger = panels catch up faster. ~10 feels "attached" but still smooth
    var followSpeed: Float = 10

    //start head tracking (no permission popup needed for this one)
    func start() async {
        guard WorldTrackingProvider.isSupported else {
            print("HeadFollower: head tracking isn't supported here, panels will stay put")
            return
        }
        let provider = WorldTrackingProvider()
        worldTracking = provider
        do {
            try await session.run([provider])
        } catch {
            print("HeadFollower: couldn't start head tracking: \(error)")
        }
    }

    func stop() {
        session.stop()
        subscription?.cancel()
        subscription = nil
    }

    //call once from RealityView's make closure with the entity holding all the panels
    func follow(_ hud: Entity, in content: RealityViewContent) {
        subscription = content.subscribe(to: SceneEvents.Update.self) { [weak self, weak hud] event in
            guard let self, let hud else { return }
            self.step(hud, deltaTime: Float(event.deltaTime))
        }
    }

    private func step(_ hud: Entity, deltaTime: Float) {
        guard let worldTracking,
              worldTracking.state == .running,
              let device = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()),
              device.isTracked else { return }

        let head = Transform(matrix: device.originFromAnchorTransform)
        lastHeadPosition = head.translation

        //first frame: jump straight there so the panels don't fly in from across the room
        if !hasPlaced {
            hud.position = head.translation
            hud.orientation = head.rotation
            hasPlaced = true
            return
        }

        //move part of the way there each frame (same speed no matter the frame rate)
        let t = 1 - exp(-followSpeed * deltaTime)
        hud.position = hud.position + (head.translation - hud.position) * t
        hud.orientation = simd_slerp(hud.orientation, head.rotation, t)
    }
}
#endif
