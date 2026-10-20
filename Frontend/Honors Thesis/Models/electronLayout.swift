//
//  electronLayout.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/27/26.
//works out the lone pairs and unpaired electrons on each atom and where to draw the dots.
//used by the "show electrons" toggle (2D + 3D) and by the Lewis structure diagram.
//
//counting:
//  nonbonding electrons = valence electrons - (sum of bond orders) - charge
//  then like a Lewis dot drawing, the atom has 4 "sides" (H and He have 1).
//  each bond order uses up a side, and leftover electrons go one per free side first,
//  then start pairing up (Hund's rule, basically).
//  e.g. O in water: 6 - 2 = 4 left, 2 free sides -> 2 lone pairs
//       lone C atom: 4 left, 4 free sides -> 4 unpaired
//       CH3 (methyl radical): 4 - 3 = 1 left -> 1 unpaired
//
//placing: dots go in the directions that are farthest from the bonds and from each other.

import Foundation //sqrt, cos, sin
import simd

struct ElectronCount: Equatable {
    let lonePairs: Int
    let unpaired: Int
    var isEmpty: Bool { lonePairs == 0 && unpaired == 0 }
}

enum ElectronLayout {

    // MARK: - counting

    static func bondOrder(_ type: BondType) -> Int {
        switch type {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }

    //nil = we don't draw electrons for this element (transition metals etc.)
    static func count(for atom: Atom, bonds: [Bond]) -> ElectronCount? {
        guard let valence = Elements.info(for: atom.name)?.valenceElectrons else { return nil }
        let bondOrderSum = bonds
            .filter { $0.idAtom1 == atom.idAtom || $0.idAtom2 == atom.idAtom }
            .reduce(0) { $0 + bondOrder($1.bondType) }
        let charge = 0 //TODO: use atom.charge once the Swift Atom has a charge field
        let nonbonding = max(0, valence - bondOrderSum - charge)

        let sides = (atom.name == "H" || atom.name == "He") ? 1 : 4
        let freeSides = max(0, sides - bondOrderSum)
        let unpaired: Int
        if nonbonding <= freeSides {
            unpaired = nonbonding //one per side, nothing has to pair up yet
        } else {
            unpaired = max(2 * freeSides - nonbonding, nonbonding % 2) //extras pair up
        }
        return ElectronCount(lonePairs: (nonbonding - unpaired) / 2, unpaired: unpaired)
    }

    // MARK: - placing

    //~200 directions spread evenly over a sphere (for 3D), first one points straight up
    static let sphereDirections: [SIMD3<Float>] = {
        let n = 200
        let golden = Float.pi * (3 - sqrt(5))
        return (0..<n).map { i in
            let y = 1 - 2 * (Float(i) + 0.5) / Float(n)
            let radius = sqrt(max(0, 1 - y * y))
            let angle = golden * Float(i)
            return SIMD3(cos(angle) * radius, y, sin(angle) * radius)
        }
    }()

    //72 directions around a circle in a flat plane (for 2D and the Lewis diagram), starting at "up"
    static func circleDirections(right: SIMD3<Float>, up: SIMD3<Float>) -> [SIMD3<Float>] {
        (0..<72).map { i in
            let angle = Float(i) / 72 * 2 * .pi
            return up * cos(angle) + right * sin(angle)
        }
    }

    //SwiftUI screens: y points DOWN, so "up" is -y (this way a lone atom's first dot goes on top)
    static let screenDirections = circleDirections(right: SIMD3(1, 0, 0), up: SIMD3(0, -1, 0))

    //greedy: each new group goes where it's farthest from every bond and every group already placed
    static func spreadDirections(count: Int, avoiding bondDirections: [SIMD3<Float>], candidates: [SIMD3<Float>]) -> [SIMD3<Float>] {
        guard count > 0, !candidates.isEmpty else { return [] }
        var chosen: [SIMD3<Float>] = []
        for _ in 0..<count {
            let taken = bondDirections + chosen
            var best = candidates[0]
            var bestClosest = Float.infinity
            for candidate in candidates {
                //how close is the closest thing already there? (dot = cos of the angle, bigger = closer)
                let closest = taken.map { simd_dot(candidate, $0) }.max() ?? -1
                if closest < bestClosest - 0.0001 {
                    bestClosest = closest
                    best = candidate
                }
            }
            chosen.append(best)
        }
        return chosen
    }

    //every dot's position for one atom.
    //distance = how far from the atom's center, pairSpacing = gap between the two dots of a pair,
    //sideways = a direction the pair's two dots should spread along (usually the viewing direction)
    static func dotPositions(center: SIMD3<Float>,
                             bondDirections: [SIMD3<Float>],
                             electrons: ElectronCount,
                             distance: Float,
                             pairSpacing: Float,
                             candidates: [SIMD3<Float>],
                             sideways: SIMD3<Float>) -> [SIMD3<Float>] {
        let groups = electrons.lonePairs + electrons.unpaired
        let directions = spreadDirections(count: groups, avoiding: bondDirections.map(safeNormalize), candidates: candidates)
        var dots: [SIMD3<Float>] = []
        for (i, direction) in directions.enumerated() {
            let spot = center + direction * distance
            if i < electrons.lonePairs {
                //a pair = two dots side by side, across the direction they point
                var across = simd_cross(direction, sideways)
                if simd_length(across) < 0.001 { across = simd_cross(direction, SIMD3(0, 1, 0)) }
                if simd_length(across) < 0.001 { across = simd_cross(direction, SIMD3(1, 0, 0)) }
                across = simd_normalize(across) * (pairSpacing / 2)
                dots.append(spot + across)
                dots.append(spot - across)
            } else {
                dots.append(spot) //unpaired = one dot
            }
        }
        return dots
    }

    private static func safeNormalize(_ v: SIMD3<Float>) -> SIMD3<Float> {
        let length = simd_length(v)
        return length > 0.00001 ? v / length : SIMD3(0, 1, 0)
    }
}
