from schemas import BondType
from Validation.elements import Element
from Validation.errors import tooManyBondsError, bondNotYetImplementedError

#i'm making it a class and the purpose of it is to check that two elements are bonded correctly. 

class Bonding:
    def __init__(self, element1: Element, element2: Element, bondAvail1: int, bondAvail2: int, bondType: BondType):
        self.element1 = element1
        self.element2 = element2
        self.bondAvail1 = bondAvail1
        self.bondAvail2 = bondAvail2
        self.bondType = bondType

#i need to figure out what type of bond it is
#I'm only gonna focus on the actual logic for covalent bonds right now

    '''
    code explanation (this is before i actually write the code)

    method: 
        for atom in molecule #this will go in a different file bc it deals with molecules and not just bonding
            get the element of the atom
            get the number of bonds that atom has 
            if the number of bonds is greater than the max number of bonds for that element, return false
        else, return true

        for each bond in molecule
            get the two elements involved in the bond
            check the bond type category (ionic, covalent, metallic)
            if the bond type is not covalent:
                send a "not yet implemented" error
            if the bond type is covalent:
                check the number of valence electrons available for each atom 
                check the bond type (single, double, triple)
                if the bond type is more than the number of valence electrons available for either atom
                    send an invalid bond error
                else
                    for each atom
                        number of valence electrons available = number of valence electrons available - bond type (single = 1, double = 2, triple = 3)

    '''

    def determineBondCategory(self, element1: Element, element2: Element) -> str:
        if element1.isMetal and element2.isMetal:
            return "metallic"
        else:
            electronegativityDif = abs(element1.electronegativity - element2.electronegativity)
            if electronegativityDif >= 1.7:
                return "ionic"
            else:
                return "covalent"

    def validateCovalentBond(self, element1: Element, element2: Element, bondAvail1: int, bondAvail2: int, bondType: BondType) -> tuple[bool, list[str]]:
        element1 = self.element1
        element2 = self.element2
        bondAvail1 = self.bondAvail1
        bondAvail2 = self.bondAvail2
        bondType = self.bondType
        errors = list[str]
        if bondType == BondType.single:
            bondNum = 1
        elif bondType == BondType.double:
            bondNum = 2
        elif bondType == BondType.triple:
            bondNum = 3

        if bondAvail1 < bondNum:
            errors.append(tooManyBondsError(element1))
        if bondAvail2 < bondNum:
            errors.append(tooManyBondsError(element2))

        if len(errors) == 0:
            bondAvail1 -= bondNum
            bondAvail2 -= bondNum
            return tuple[True, errors]
        else: 
            return tuple[False, errors]

    def validateIonicBond(self) -> tuple[bool, list[str]]:
        errors = list[str]
        errors.append(bondNotYetImplementedError("ionic"))
        return tuple[False, errors]

    def validateMetallicBond(self) -> tuple[bool, list[str]]:
        errors = list[str]
        errors.append(bondNotYetImplementedError("metallic"))
        return tuple[False, errors]


    def validateBond(self, element1: Element, element2: Element, bondAvail1: int, bondAvail2: int, bondType: BondType) -> tuple[bool, list[str]]:
        bondCategory = self.determineBondCategory(element1, element2)
        if bondCategory == "covalent":
            return self.validateCovalentBond(element1, element2, bondAvail1, bondAvail2, bondType)
        elif bondCategory == "ionic":
            return self.validateIonicBond()
        elif bondCategory == "metallic":
            return self.validateMetallicBond()


