'''
okay so here i want to just have each element and then it'll have all of its properties.

'''

from dataclasses import dataclass

@dataclass
class Element:
    name: str
    symbol: str
    atomicNumber: int
    valenceElectrons: int
    period: int
    group: int
    electronegativity: float | None
    maxBonds: list[int] | None
    isMetal: bool
    atomicMass: float


# ask dr. jose abt hypervalent nonmetals
# ask dr. jose about francium
# ask dr jose abt noble gas electronegativity
# ask dr jose about the atomic mass of lithium and if there's any other elements with ambiguous atomic masses

ELEMENTS: dict[str, Element] = {
    "H": Element(name="Hydrogen", symbol="H", atomicNumber=1, valenceElectrons=1, period=1, group=1, electronegativity=2.20, maxBonds=[1], isMetal=False, atomicMass=1.0080),
    "He": Element(name="Helium", symbol="He", atomicNumber=2, valenceElectrons=2, period=1, group=18, electronegativity=None, maxBonds=[0], isMetal=False, atomicMass=4.00260),
    "Li": Element(name="Lithium", symbol="Li", atomicNumber=3, valenceElectrons=1, period=2, group=1, electronegativity=0.98, maxBonds=[1], isMetal=True, atomicMass=6.94),
    "Be": Element(name="Beryllium", symbol="Be", atomicNumber=4, valenceElectrons=2, period=2, group=2, electronegativity=1.57, maxBonds=[2], isMetal=True, atomicMass=9.0122),
    "B": Element(name="Boron", symbol="B", atomicNumber=5, valenceElectrons=3, period=2, group=13, electronegativity=2.04, maxBonds=[3], isMetal=False, atomicMass=10.81),
    "C": Element(name="Carbon", symbol="C", atomicNumber=6, valenceElectrons=4, period=2, group=14, electronegativity=2.55, maxBonds=[4], isMetal=False, atomicMass=12.011),
    "N": Element(name="Nitrogen", symbol="N", atomicNumber=7, valenceElectrons=5, period=2, group=15, electronegativity=3.04, maxBonds=[3], isMetal=False, atomicMass=14.007),
    "O": Element(name="Oxygen", symbol="O", atomicNumber=8, valenceElectrons=6, period=2, group=16, electronegativity=3.44, maxBonds=[2], isMetal=False, atomicMass=15.999),
    "F": Element(name="Fluorine", symbol="F", atomicNumber=9, valenceElectrons=7, period=2, group=17, electronegativity=3.98, maxBonds=[1], isMetal=False, atomicMass=18.998),
    "Ne": Element(name="Neon", symbol="Ne", atomicNumber=10, valenceElectrons=8, period=2, group=18, electronegativity=None, maxBonds=[0], isMetal=False, atomicMass=20.180),
    "Na": Element(name="Sodium", symbol="Na", atomicNumber=11, valenceElectrons=1, period=3, group=1, electronegativity=0.93, maxBonds=[1], isMetal=True, atomicMass=22.990),
    "Mg": Element(name="Magnesium", symbol="Mg", atomicNumber=12, valenceElectrons=2, period=3, group=2, electronegativity=1.31, maxBonds=[2], isMetal=True, atomicMass=24.305),
    "Al": Element(name="Aluminum", symbol="Al", atomicNumber=13, valenceElectrons=3, period=3, group=13, electronegativity=1.61, maxBonds=[3], isMetal=True, atomicMass=26.982),
    "Si": Element(name="Silicon", symbol="Si", atomicNumber=14, valenceElectrons=4, period=3, group=14, electronegativity=1.90, maxBonds=[4], isMetal=False, atomicMass=28.085),
    "P": Element(name="Phosphorus", symbol="P", atomicNumber=15, valenceElectrons=5, period=3, group=15, electronegativity=2.19, maxBonds=[3], isMetal=False, atomicMass=30.974),
    "S": Element(name="Sulfur", symbol="S", atomicNumber=16, valenceElectrons=6, period=3, group=16, electronegativity=2.58, maxBonds=[2], isMetal=False, atomicMass=32.06),
    "Cl": Element(name="Chlorine", symbol="Cl", atomicNumber=17, valenceElectrons=7, period=3, group=17, electronegativity=3.16, maxBonds=[1], isMetal=False, atomicMass=35.45),
    "Ar": Element(name="Argon", symbol="Ar", atomicNumber=18, valenceElectrons=8, period=3, group=18, electronegativity=None, maxBonds=[0], isMetal=False, atomicMass=39.948),
    "K": Element(name="Potassium", symbol="K", atomicNumber=19, valenceElectrons=1, period=4, group=1, electronegativity=0.82, maxBonds=[1], isMetal=True, atomicMass=39.098),
    "Ca": Element(name="Calcium", symbol="Ca", atomicNumber=20, valenceElectrons=2, period=4, group=2, electronegativity=1.00, maxBonds=[2], isMetal=True, atomicMass=40.078),
    "Sc": Element(name="Scandium", symbol="Sc", atomicNumber=21, valenceElectrons=3, period=4, group=3, electronegativity=1.36, maxBonds=None, isMetal=True, atomicMass=44.956),
    "Ti": Element(name="Titanium", symbol="Ti", atomicNumber=22, valenceElectrons=4, period=4, group=4, electronegativity=1.54, maxBonds=None, isMetal=True, atomicMass=47.867),
    "V": Element(name="Vanadium", symbol="V", atomicNumber=23, valenceElectrons=5, period=4, group=5, electronegativity=1.63, maxBonds=None, isMetal=True, atomicMass=50.942),
    "Cr": Element(name="Chromium", symbol="Cr", atomicNumber=24, valenceElectrons=6, period=4, group=6, electronegativity=1.66, maxBonds=None, isMetal=True, atomicMass=51.996),
    "Mn": Element(name="Manganese", symbol="Mn", atomicNumber=25, valenceElectrons=7, period=4, group=7, electronegativity=1.55, maxBonds=None, isMetal=True, atomicMass=54.938),
    "Fe": Element(name="Iron", symbol="Fe", atomicNumber=26, valenceElectrons=8, period=4, group=8, electronegativity=1.83, maxBonds=None, isMetal=True, atomicMass=55.845),
    "Co": Element(name="Cobalt", symbol="Co", atomicNumber=27, valenceElectrons=9, period=4, group=9, electronegativity=1.88, maxBonds=None, isMetal=True, atomicMass=58.933),
    "Ni": Element(name="Nickel", symbol="Ni", atomicNumber=28, valenceElectrons=10, period=4, group=10, electronegativity=1.91, maxBonds=None, isMetal=True, atomicMass=58.693),
    "Cu": Element(name="Copper", symbol="Cu", atomicNumber=29, valenceElectrons=11, period=4, group=11, electronegativity=1.90, maxBonds=None, isMetal=True, atomicMass=63.546),
    "Zn": Element(name="Zinc", symbol="Zn", atomicNumber=30, valenceElectrons=12, period=4, group=12, electronegativity=1.65, maxBonds=None, isMetal=True, atomicMass=65.38),
    "Ga": Element(name="Gallium", symbol="Ga", atomicNumber=31, valenceElectrons=3, period=4, group=13, electronegativity=1.81, maxBonds=[3], isMetal=True, atomicMass=69.723),
    "Ge": Element(name="Germanium", symbol="Ge", atomicNumber=32, valenceElectrons=4, period=4, group=14, electronegativity=2.01, maxBonds=[4], isMetal=False, atomicMass=72.63),
    "As": Element(name="Arsenic", symbol="As", atomicNumber=33, valenceElectrons=5, period=4, group=15, electronegativity=2.18, maxBonds=[3], isMetal=False, atomicMass=74.922),
    "Se": Element(name="Selenium", symbol="Se", atomicNumber=34, valenceElectrons=6, period=4, group=16, electronegativity=2.55, maxBonds=[2], isMetal=False, atomicMass=78.971),
    "Br": Element(name="Bromine", symbol="Br", atomicNumber=35, valenceElectrons=7, period=4, group=17, electronegativity=2.96, maxBonds=[1], isMetal=False, atomicMass=79.904),
    "Kr": Element(name="Krypton", symbol="Kr", atomicNumber=36, valenceElectrons=8, period=4, group=18, electronegativity=3.00, maxBonds=[0], isMetal=False, atomicMass=83.798),
    "Rb": Element(name="Rubidium", symbol="Rb", atomicNumber=37, valenceElectrons=1, period=5, group=1, electronegativity=0.82, maxBonds=[1], isMetal=True, atomicMass=85.468),
    "Sr": Element(name="Strontium", symbol="Sr", atomicNumber=38, valenceElectrons=2, period=5, group=2, electronegativity=0.95, maxBonds=[2], isMetal=True, atomicMass=87.62),
    "Y": Element(name="Yttrium", symbol="Y", atomicNumber=39, valenceElectrons=3, period=5, group=3, electronegativity=1.22, maxBonds=None, isMetal=True, atomicMass=88.907),
    "Zr": Element(name="Zirconium", symbol="Zr", atomicNumber=40, valenceElectrons=4, period=5, group=4, electronegativity=1.33, maxBonds=None, isMetal=True, atomicMass=91.224),
    "Nb": Element(name="Niobium", symbol="Nb", atomicNumber=41, valenceElectrons=5, period=5, group=5, electronegativity=1.60, maxBonds=None, isMetal=True, atomicMass=92.906),
    "Mo": Element(name="Molybdenum", symbol="Mo", atomicNumber=42, valenceElectrons=6, period=5, group=6, electronegativity=2.16, maxBonds=None, isMetal=True, atomicMass=95.95),
    "Tc": Element(name="Technetium", symbol="Tc", atomicNumber=43, valenceElectrons=7, period=5, group=7, electronegativity=1.90, maxBonds=None, isMetal=True, atomicMass=98),
    "Ru": Element(name="Ruthenium", symbol="Ru", atomicNumber=44, valenceElectrons=8, period=5, group=8, electronegativity=2.20, maxBonds=None, isMetal=True, atomicMass=101.07),
    "Rh": Element(name="Rhodium", symbol="Rh", atomicNumber=45, valenceElectrons=9, period=5, group=9, electronegativity=2.28, maxBonds=None, isMetal=True, atomicMass=102.91),
    "Pd": Element(name="Palladium", symbol="Pd", atomicNumber=46, valenceElectrons=10, period=5, group=10, electronegativity=2.20, maxBonds=None, isMetal=True, atomicMass=106.42),
    "Ag": Element(name="Silver", symbol="Ag", atomicNumber=47, valenceElectrons=11, period=5, group=11, electronegativity=1.93, maxBonds=None, isMetal=True, atomicMass=107.87),
    "Cd": Element(name="Cadmium", symbol="Cd", atomicNumber=48, valenceElectrons=12, period=5, group=12, electronegativity=1.69, maxBonds=None, isMetal=True, atomicMass=112.41),
    "In": Element(name="Indium", symbol="In", atomicNumber=49, valenceElectrons=3, period=5, group=13, electronegativity=1.78, maxBonds=[3], isMetal=True, atomicMass=114.82),
    "Sn": Element(name="Tin", symbol="Sn", atomicNumber=50, valenceElectrons=4, period=5, group=14, electronegativity=1.96, maxBonds=[2, 4], isMetal=True, atomicMass=118.71),
    "Sb": Element(name="Antimony", symbol="Sb", atomicNumber=51, valenceElectrons=5, period=5, group=15, electronegativity=2.05, maxBonds=[3], isMetal=False, atomicMass=121.76),
    "Te": Element(name="Tellurium", symbol="Te", atomicNumber=52, valenceElectrons=6, period=5, group=16, electronegativity=2.10, maxBonds=[2], isMetal=False, atomicMass=127.60),
    "I": Element(name="Iodine", symbol="I", atomicNumber=53, valenceElectrons=7, period=5, group=17, electronegativity=2.66, maxBonds=[1], isMetal=False, atomicMass=126.90),
    "Xe": Element(name="Xenon", symbol="Xe", atomicNumber=54, valenceElectrons=8, period=5, group=18, electronegativity=2.60, maxBonds=[0], isMetal=False, atomicMass=131.29),
    "Cs": Element(name="Cesium", symbol="Cs", atomicNumber=55, valenceElectrons=1, period=6, group=1, electronegativity=0.79, maxBonds=[1], isMetal=True, atomicMass=132.91),
    "Ba": Element(name="Barium", symbol="Ba", atomicNumber=56, valenceElectrons=2, period=6, group=2, electronegativity=0.89, maxBonds=[2], isMetal=True, atomicMass=137.33),
    "La": Element(name="Lanthanum", symbol="La", atomicNumber=57, valenceElectrons=3, period=6, group=3, electronegativity=1.10, maxBonds=None, isMetal=True, atomicMass=138.91),
    "Ce": Element(name="Cerium", symbol="Ce", atomicNumber=58, valenceElectrons=4, period=6, group=3, electronegativity=1.12, maxBonds=None, isMetal=True, atomicMass=140.12),
    "Pr": Element(name="Praseodymium", symbol="Pr", atomicNumber=59, valenceElectrons=5, period=6, group=3, electronegativity=1.13, maxBonds=None, isMetal=True, atomicMass=140.91),
    "Nd": Element(name="Neodymium", symbol="Nd", atomicNumber=60, valenceElectrons=6, period=6, group=3, electronegativity=1.14, maxBonds=None, isMetal=True, atomicMass=144.24),
    "Pm": Element(name="Promethium", symbol="Pm", atomicNumber=61, valenceElectrons=7, period=6, group=3, electronegativity=1.13, maxBonds=None, isMetal=True, atomicMass=145),
    "Sm": Element(name="Samarium", symbol="Sm", atomicNumber=62, valenceElectrons=8, period=6, group=3, electronegativity=1.17, maxBonds=None, isMetal=True, atomicMass=150.36),
    "Eu": Element(name="Europium", symbol="Eu", atomicNumber=63, valenceElectrons=9, period=6, group=3, electronegativity=1.20, maxBonds=None, isMetal=True, atomicMass=151.96),
    "Gd": Element(name="Gadolinium", symbol="Gd", atomicNumber=64, valenceElectrons=10, period=6, group=3, electronegativity=1.20, maxBonds=None, isMetal=True, atomicMass=157.25),
    "Tb": Element(name="Terbium", symbol="Tb", atomicNumber=65, valenceElectrons=11, period=6, group=3, electronegativity=1.20, maxBonds=None, isMetal=True, atomicMass=158.93),
    "Dy": Element(name="Dysprosium", symbol="Dy", atomicNumber=66, valenceElectrons=12, period=6, group=3, electronegativity=1.22, maxBonds=None, isMetal=True, atomicMass=162.50),
    "Ho": Element(name="Holmium", symbol="Ho", atomicNumber=67, valenceElectrons=13, period=6, group=3, electronegativity=1.23, maxBonds=None, isMetal=True, atomicMass=164.93),
    "Er": Element(name="Erbium", symbol="Er", atomicNumber=68, valenceElectrons=14, period=6, group=3, electronegativity=1.24, maxBonds=None, isMetal=True, atomicMass=167.26),
    "Tm": Element(name="Thulium", symbol="Tm", atomicNumber=69, valenceElectrons=15, period=6, group=3, electronegativity=1.25, maxBonds=None, isMetal=True, atomicMass=168.93),
    "Yb": Element(name="Ytterbium", symbol="Yb", atomicNumber=70, valenceElectrons=16, period=6, group=3, electronegativity=1.10, maxBonds=None, isMetal=True, atomicMass=173.04),
    "Lu": Element(name="Lutetium", symbol="Lu", atomicNumber=71, valenceElectrons=17, period=6, group=3, electronegativity=1.27, maxBonds=None, isMetal=True, atomicMass=174.97),
    "Hf": Element(name="Hafnium", symbol="Hf", atomicNumber=72, valenceElectrons=4, period=6, group=4, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=178.49),
    "Ta": Element(name="Tantalum", symbol="Ta", atomicNumber=73, valenceElectrons=5, period=6, group=5, electronegativity=1.50, maxBonds=None, isMetal=True, atomicMass=180.95),
    "W": Element(name="Tungsten", symbol="W", atomicNumber=74, valenceElectrons=6, period=6, group=6, electronegativity=2.36, maxBonds=None, isMetal=True, atomicMass=183.84),
    "Re": Element(name="Rhenium", symbol="Re", atomicNumber=75, valenceElectrons=7, period=6, group=7, electronegativity=1.90, maxBonds=None, isMetal=True, atomicMass=186.21),
    "Os": Element(name="Osmium", symbol="Os", atomicNumber=76, valenceElectrons=8, period=6, group=8, electronegativity=2.20, maxBonds=None, isMetal=True, atomicMass=190.23),
    "Ir": Element(name="Iridium", symbol="Ir", atomicNumber=77, valenceElectrons=9, period=6, group=9, electronegativity=2.20, maxBonds=None, isMetal=True, atomicMass=192.22),
    "Pt": Element(name="Platinum", symbol="Pt", atomicNumber=78, valenceElectrons=10, period=6, group=10, electronegativity=2.28, maxBonds=None, isMetal=True, atomicMass=195.08),
    "Au": Element(name="Gold", symbol="Au", atomicNumber=79, valenceElectrons=11, period=6, group=11, electronegativity=2.54, maxBonds=None, isMetal=True, atomicMass=196.97),
    "Hg": Element(name="Mercury", symbol="Hg", atomicNumber=80, valenceElectrons=12, period=6, group=12, electronegativity=2.00, maxBonds=None, isMetal=True, atomicMass=200.59),
    "Tl": Element(name="Thallium", symbol="Tl", atomicNumber=81, valenceElectrons=3, period=6, group=13, electronegativity=1.62, maxBonds=[1, 3], isMetal=True, atomicMass=204.38),
    "Pb": Element(name="Lead", symbol="Pb", atomicNumber=82, valenceElectrons=4, period=6, group=14, electronegativity=1.87, maxBonds=[2, 4], isMetal=True, atomicMass=207.2),
    "Bi": Element(name="Bismuth", symbol="Bi", atomicNumber=83, valenceElectrons=5, period=6, group=15, electronegativity=2.02, maxBonds=[3,5], isMetal=True, atomicMass=208.98),
    "Po": Element(name="Polonium", symbol="Po", atomicNumber=84, valenceElectrons=6, period=6, group=16, electronegativity=2.00, maxBonds=[2,4], isMetal=True, atomicMass=209),
    "At": Element(name="Astatine", symbol="At", atomicNumber=85, valenceElectrons=7, period=6, group=17, electronegativity=2.20, maxBonds=[1], isMetal=False, atomicMass=210),
    "Rn": Element(name="Radon", symbol="Rn", atomicNumber=86, valenceElectrons=8, period=6, group=18, electronegativity=None, maxBonds=[0], isMetal=False, atomicMass=222),
    "Fr": Element(name="Francium", symbol="Fr", atomicNumber=87, valenceElectrons=1, period=7, group=1, electronegativity=None, maxBonds=[1], isMetal=True, atomicMass=223),
    "Ra": Element(name="Radium", symbol="Ra", atomicNumber=88, valenceElectrons=2, period=7, group=2, electronegativity=0.90, maxBonds=[2], isMetal=True, atomicMass=226),
    "Ac": Element(name="Actinium", symbol="Ac", atomicNumber=89, valenceElectrons=3, period=7, group=3, electronegativity=1.10, maxBonds=None, isMetal=True, atomicMass=227),
    "Th": Element(name="Thorium", symbol="Th", atomicNumber=90, valenceElectrons=4, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=232.04),
    "Pa": Element(name="Protactinium", symbol="Pa", atomicNumber=91, valenceElectrons=5, period=7, group=3, electronegativity=1.50, maxBonds=None, isMetal=True, atomicMass=231.04),
    "U": Element(name="Uranium", symbol="U", atomicNumber=92, valenceElectrons=6, period=7, group=3, electronegativity=1.38, maxBonds=None, isMetal=True, atomicMass=238.03),
    "Np": Element(name="Neptunium", symbol="Np", atomicNumber=93, valenceElectrons=7, period=7, group=3, electronegativity=1.36, maxBonds=None, isMetal=True, atomicMass=237),
    "Pu": Element(name="Plutonium", symbol="Pu", atomicNumber=94, valenceElectrons=8, period=7, group=3, electronegativity=1.28, maxBonds=None, isMetal=True, atomicMass=244),
    "Am": Element(name="Americium", symbol="Am", atomicNumber=95, valenceElectrons=9, period=7, group=3, electronegativity=1.13, maxBonds=None, isMetal=True, atomicMass=243),
    "Cm": Element(name="Curium", symbol="Cm", atomicNumber=96, valenceElectrons=10, period=7, group=3, electronegativity=1.28, maxBonds=None, isMetal=True, atomicMass=247),
    "Bk": Element(name="Berkelium", symbol="Bk", atomicNumber=97, valenceElectrons=11, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=247),
    "Cf": Element(name="Californium", symbol="Cf", atomicNumber=98, valenceElectrons=12, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=251),
    "Es": Element(name="Einsteinium", symbol="Es", atomicNumber=99, valenceElectrons=13, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=252),
    "Fm": Element(name="Fermium", symbol="Fm", atomicNumber=100, valenceElectrons=14, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=257),
    "Md": Element(name="Mendelevium", symbol="Md", atomicNumber=101, valenceElectrons=15, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=258),
    "No": Element(name="Nobelium", symbol="No", atomicNumber=102, valenceElectrons=16, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=259),
    "Lr": Element(name="Lawrencium", symbol="Lr", atomicNumber=103, valenceElectrons=17, period=7, group=3, electronegativity=1.30, maxBonds=None, isMetal=True, atomicMass=262),

    # Superheavy synthetic elements: too little chemistry has been observed to assign real common oxidation states. maxBonds below is a best-guess, go over this with Dr. Jose
    
    "Rf": Element(name="Rutherfordium", symbol="Rf", atomicNumber=104, valenceElectrons=4, period=7, group=4, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=267),
    "Db": Element(name="Dubnium", symbol="Db", atomicNumber=105, valenceElectrons=5, period=7, group=5, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=270),
    "Sg": Element(name="Seaborgium", symbol="Sg", atomicNumber=106, valenceElectrons=6, period=7, group=6, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=271),
    "Bh": Element(name="Bohrium", symbol="Bh", atomicNumber=107, valenceElectrons=7, period=7, group=7, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=270),
    "Hs": Element(name="Hassium", symbol="Hs", atomicNumber=108, valenceElectrons=8, period=7, group=8, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=277),
    "Mt": Element(name="Meitnerium", symbol="Mt", atomicNumber=109, valenceElectrons=9, period=7, group=9, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=276),
    "Ds": Element(name="Darmstadtium", symbol="Ds", atomicNumber=110, valenceElectrons=10, period=7, group=10, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=281),
    "Rg": Element(name="Roentgenium", symbol="Rg", atomicNumber=111, valenceElectrons=11, period=7, group=11, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=282),
    "Cn": Element(name="Copernicium", symbol="Cn", atomicNumber=112, valenceElectrons=12, period=7, group=12, electronegativity=None, maxBonds=None, isMetal=True, atomicMass=285),
    "Nh": Element(name="Nihonium", symbol="Nh", atomicNumber=113, valenceElectrons=3, period=7, group=13, electronegativity=None, maxBonds=[1], isMetal=True, atomicMass=286),
    "Fl": Element(name="Flerovium", symbol="Fl", atomicNumber=114, valenceElectrons=4, period=7, group=14, electronegativity=None, maxBonds=[2], isMetal=True, atomicMass=289),
    "Mc": Element(name="Moscovium", symbol="Mc", atomicNumber=115, valenceElectrons=5, period=7, group=15, electronegativity=None, maxBonds=[3], isMetal=True, atomicMass=288),
    "Lv": Element(name="Livermorium", symbol="Lv", atomicNumber=116, valenceElectrons=6, period=7, group=16, electronegativity=None, maxBonds=[2], isMetal=True, atomicMass=293),
    "Ts": Element(name="Tennessine", symbol="Ts", atomicNumber=117, valenceElectrons=7, period=7, group=17, electronegativity=None, maxBonds=[1], isMetal=False, atomicMass=294),
    "Og": Element(name="Oganesson", symbol="Og", atomicNumber=118, valenceElectrons=8, period=7, group=18, electronegativity=None, maxBonds=[0], isMetal=False, atomicMass=294),
}