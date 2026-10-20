//
//  Elements.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/20/26.
//every element the builder can add, plus the colors both the 2D and 3D views use.
//the list matches Validation/elements.py in the backend.

import SwiftUI

struct ElementInfo: Identifiable, Hashable {
    let number: Int
    let symbol: String
    let name: String
    let group: Int //periodic table column 1-18 (lanthanides/actinides are listed as 3)
    var id: String { symbol }

    //valence electrons, only for main-group elements (columns 1, 2, 13-18)
    //transition metals don't follow the simple octet rules, so they get nil and no electron dots
    var valenceElectrons: Int? {
        if symbol == "He" { return 2 }
        switch group {
        case 1, 2: return group
        case 13...18: return group - 10
        default: return nil
        }
    }
}

enum Elements {
    //the ones people use all the time, shown as big buttons at the top of the sidebar
    static let commonSymbols = ["H", "C", "N", "O", "F", "P", "S", "Cl", "Br", "I"]

    static func info(for symbol: String) -> ElementInfo? {
        all.first { $0.symbol == symbol }
    }

    static var common: [ElementInfo] {
        commonSymbols.compactMap { symbol in all.first { $0.symbol == symbol } }
    }

    //the whole periodic table in order
    static let all: [ElementInfo] = [
        ElementInfo(number: 1, symbol: "H", name: "Hydrogen", group: 1),
        ElementInfo(number: 2, symbol: "He", name: "Helium", group: 18),
        ElementInfo(number: 3, symbol: "Li", name: "Lithium", group: 1),
        ElementInfo(number: 4, symbol: "Be", name: "Beryllium", group: 2),
        ElementInfo(number: 5, symbol: "B", name: "Boron", group: 13),
        ElementInfo(number: 6, symbol: "C", name: "Carbon", group: 14),
        ElementInfo(number: 7, symbol: "N", name: "Nitrogen", group: 15),
        ElementInfo(number: 8, symbol: "O", name: "Oxygen", group: 16),
        ElementInfo(number: 9, symbol: "F", name: "Fluorine", group: 17),
        ElementInfo(number: 10, symbol: "Ne", name: "Neon", group: 18),
        ElementInfo(number: 11, symbol: "Na", name: "Sodium", group: 1),
        ElementInfo(number: 12, symbol: "Mg", name: "Magnesium", group: 2),
        ElementInfo(number: 13, symbol: "Al", name: "Aluminum", group: 13),
        ElementInfo(number: 14, symbol: "Si", name: "Silicon", group: 14),
        ElementInfo(number: 15, symbol: "P", name: "Phosphorus", group: 15),
        ElementInfo(number: 16, symbol: "S", name: "Sulfur", group: 16),
        ElementInfo(number: 17, symbol: "Cl", name: "Chlorine", group: 17),
        ElementInfo(number: 18, symbol: "Ar", name: "Argon", group: 18),
        ElementInfo(number: 19, symbol: "K", name: "Potassium", group: 1),
        ElementInfo(number: 20, symbol: "Ca", name: "Calcium", group: 2),
        ElementInfo(number: 21, symbol: "Sc", name: "Scandium", group: 3),
        ElementInfo(number: 22, symbol: "Ti", name: "Titanium", group: 4),
        ElementInfo(number: 23, symbol: "V", name: "Vanadium", group: 5),
        ElementInfo(number: 24, symbol: "Cr", name: "Chromium", group: 6),
        ElementInfo(number: 25, symbol: "Mn", name: "Manganese", group: 7),
        ElementInfo(number: 26, symbol: "Fe", name: "Iron", group: 8),
        ElementInfo(number: 27, symbol: "Co", name: "Cobalt", group: 9),
        ElementInfo(number: 28, symbol: "Ni", name: "Nickel", group: 10),
        ElementInfo(number: 29, symbol: "Cu", name: "Copper", group: 11),
        ElementInfo(number: 30, symbol: "Zn", name: "Zinc", group: 12),
        ElementInfo(number: 31, symbol: "Ga", name: "Gallium", group: 13),
        ElementInfo(number: 32, symbol: "Ge", name: "Germanium", group: 14),
        ElementInfo(number: 33, symbol: "As", name: "Arsenic", group: 15),
        ElementInfo(number: 34, symbol: "Se", name: "Selenium", group: 16),
        ElementInfo(number: 35, symbol: "Br", name: "Bromine", group: 17),
        ElementInfo(number: 36, symbol: "Kr", name: "Krypton", group: 18),
        ElementInfo(number: 37, symbol: "Rb", name: "Rubidium", group: 1),
        ElementInfo(number: 38, symbol: "Sr", name: "Strontium", group: 2),
        ElementInfo(number: 39, symbol: "Y", name: "Yttrium", group: 3),
        ElementInfo(number: 40, symbol: "Zr", name: "Zirconium", group: 4),
        ElementInfo(number: 41, symbol: "Nb", name: "Niobium", group: 5),
        ElementInfo(number: 42, symbol: "Mo", name: "Molybdenum", group: 6),
        ElementInfo(number: 43, symbol: "Tc", name: "Technetium", group: 7),
        ElementInfo(number: 44, symbol: "Ru", name: "Ruthenium", group: 8),
        ElementInfo(number: 45, symbol: "Rh", name: "Rhodium", group: 9),
        ElementInfo(number: 46, symbol: "Pd", name: "Palladium", group: 10),
        ElementInfo(number: 47, symbol: "Ag", name: "Silver", group: 11),
        ElementInfo(number: 48, symbol: "Cd", name: "Cadmium", group: 12),
        ElementInfo(number: 49, symbol: "In", name: "Indium", group: 13),
        ElementInfo(number: 50, symbol: "Sn", name: "Tin", group: 14),
        ElementInfo(number: 51, symbol: "Sb", name: "Antimony", group: 15),
        ElementInfo(number: 52, symbol: "Te", name: "Tellurium", group: 16),
        ElementInfo(number: 53, symbol: "I", name: "Iodine", group: 17),
        ElementInfo(number: 54, symbol: "Xe", name: "Xenon", group: 18),
        ElementInfo(number: 55, symbol: "Cs", name: "Cesium", group: 1),
        ElementInfo(number: 56, symbol: "Ba", name: "Barium", group: 2),
        ElementInfo(number: 57, symbol: "La", name: "Lanthanum", group: 3),
        ElementInfo(number: 58, symbol: "Ce", name: "Cerium", group: 3),
        ElementInfo(number: 59, symbol: "Pr", name: "Praseodymium", group: 3),
        ElementInfo(number: 60, symbol: "Nd", name: "Neodymium", group: 3),
        ElementInfo(number: 61, symbol: "Pm", name: "Promethium", group: 3),
        ElementInfo(number: 62, symbol: "Sm", name: "Samarium", group: 3),
        ElementInfo(number: 63, symbol: "Eu", name: "Europium", group: 3),
        ElementInfo(number: 64, symbol: "Gd", name: "Gadolinium", group: 3),
        ElementInfo(number: 65, symbol: "Tb", name: "Terbium", group: 3),
        ElementInfo(number: 66, symbol: "Dy", name: "Dysprosium", group: 3),
        ElementInfo(number: 67, symbol: "Ho", name: "Holmium", group: 3),
        ElementInfo(number: 68, symbol: "Er", name: "Erbium", group: 3),
        ElementInfo(number: 69, symbol: "Tm", name: "Thulium", group: 3),
        ElementInfo(number: 70, symbol: "Yb", name: "Ytterbium", group: 3),
        ElementInfo(number: 71, symbol: "Lu", name: "Lutetium", group: 3),
        ElementInfo(number: 72, symbol: "Hf", name: "Hafnium", group: 4),
        ElementInfo(number: 73, symbol: "Ta", name: "Tantalum", group: 5),
        ElementInfo(number: 74, symbol: "W", name: "Tungsten", group: 6),
        ElementInfo(number: 75, symbol: "Re", name: "Rhenium", group: 7),
        ElementInfo(number: 76, symbol: "Os", name: "Osmium", group: 8),
        ElementInfo(number: 77, symbol: "Ir", name: "Iridium", group: 9),
        ElementInfo(number: 78, symbol: "Pt", name: "Platinum", group: 10),
        ElementInfo(number: 79, symbol: "Au", name: "Gold", group: 11),
        ElementInfo(number: 80, symbol: "Hg", name: "Mercury", group: 12),
        ElementInfo(number: 81, symbol: "Tl", name: "Thallium", group: 13),
        ElementInfo(number: 82, symbol: "Pb", name: "Lead", group: 14),
        ElementInfo(number: 83, symbol: "Bi", name: "Bismuth", group: 15),
        ElementInfo(number: 84, symbol: "Po", name: "Polonium", group: 16),
        ElementInfo(number: 85, symbol: "At", name: "Astatine", group: 17),
        ElementInfo(number: 86, symbol: "Rn", name: "Radon", group: 18),
        ElementInfo(number: 87, symbol: "Fr", name: "Francium", group: 1),
        ElementInfo(number: 88, symbol: "Ra", name: "Radium", group: 2),
        ElementInfo(number: 89, symbol: "Ac", name: "Actinium", group: 3),
        ElementInfo(number: 90, symbol: "Th", name: "Thorium", group: 3),
        ElementInfo(number: 91, symbol: "Pa", name: "Protactinium", group: 3),
        ElementInfo(number: 92, symbol: "U", name: "Uranium", group: 3),
        ElementInfo(number: 93, symbol: "Np", name: "Neptunium", group: 3),
        ElementInfo(number: 94, symbol: "Pu", name: "Plutonium", group: 3),
        ElementInfo(number: 95, symbol: "Am", name: "Americium", group: 3),
        ElementInfo(number: 96, symbol: "Cm", name: "Curium", group: 3),
        ElementInfo(number: 97, symbol: "Bk", name: "Berkelium", group: 3),
        ElementInfo(number: 98, symbol: "Cf", name: "Californium", group: 3),
        ElementInfo(number: 99, symbol: "Es", name: "Einsteinium", group: 3),
        ElementInfo(number: 100, symbol: "Fm", name: "Fermium", group: 3),
        ElementInfo(number: 101, symbol: "Md", name: "Mendelevium", group: 3),
        ElementInfo(number: 102, symbol: "No", name: "Nobelium", group: 3),
        ElementInfo(number: 103, symbol: "Lr", name: "Lawrencium", group: 3),
        ElementInfo(number: 104, symbol: "Rf", name: "Rutherfordium", group: 4),
        ElementInfo(number: 105, symbol: "Db", name: "Dubnium", group: 5),
        ElementInfo(number: 106, symbol: "Sg", name: "Seaborgium", group: 6),
        ElementInfo(number: 107, symbol: "Bh", name: "Bohrium", group: 7),
        ElementInfo(number: 108, symbol: "Hs", name: "Hassium", group: 8),
        ElementInfo(number: 109, symbol: "Mt", name: "Meitnerium", group: 9),
        ElementInfo(number: 110, symbol: "Ds", name: "Darmstadtium", group: 10),
        ElementInfo(number: 111, symbol: "Rg", name: "Roentgenium", group: 11),
        ElementInfo(number: 112, symbol: "Cn", name: "Copernicium", group: 12),
        ElementInfo(number: 113, symbol: "Nh", name: "Nihonium", group: 13),
        ElementInfo(number: 114, symbol: "Fl", name: "Flerovium", group: 14),
        ElementInfo(number: 115, symbol: "Mc", name: "Moscovium", group: 15),
        ElementInfo(number: 116, symbol: "Lv", name: "Livermorium", group: 16),
        ElementInfo(number: 117, symbol: "Ts", name: "Tennessine", group: 17),
        ElementInfo(number: 118, symbol: "Og", name: "Oganesson", group: 18),
    ]

    // MARK: - colors

    //standard "CPK" chemistry colors as red/green/blue from 0 to 1
    //anything not listed gets pink so it still stands out
    static func rgb(for symbol: String) -> (red: Double, green: Double, blue: Double) {
        switch symbol {
        case "H": return (1.00, 1.00, 1.00)  //white
        case "C": return (0.30, 0.30, 0.30)  //dark gray
        case "N": return (0.19, 0.31, 0.97)  //blue
        case "O": return (1.00, 0.05, 0.05)  //red
        case "F", "Cl": return (0.12, 0.94, 0.12) //green
        case "Br": return (0.65, 0.16, 0.16) //dark red
        case "I": return (0.58, 0.00, 0.58)  //purple
        case "P": return (1.00, 0.50, 0.00)  //orange
        case "S": return (1.00, 0.80, 0.20)  //yellow
        case "B": return (1.00, 0.71, 0.71)  //salmon
        case "Li", "Na", "K", "Rb", "Cs", "Fr": return (0.47, 0.00, 1.00) //violet (alkali metals)
        case "Be", "Mg", "Ca", "Sr", "Ba", "Ra": return (0.00, 0.47, 0.00) //dark green (alkaline earth)
        case "Fe": return (0.88, 0.40, 0.20) //rust
        case "He", "Ne", "Ar", "Kr", "Xe", "Rn": return (0.00, 1.00, 1.00) //cyan (noble gases)
        default: return (0.87, 0.47, 1.00)   //pink
        }
    }

    static func color(for symbol: String) -> Color {
        let c = rgb(for: symbol)
        return Color(red: c.red, green: c.green, blue: c.blue)
    }

    //dark text on light atoms (like hydrogen), white text on dark ones
    static func labelColor(for symbol: String) -> Color {
        let c = rgb(for: symbol)
        let brightness = 0.299 * c.red + 0.587 * c.green + 0.114 * c.blue
        return brightness > 0.6 ? .black : .white
    }
}
