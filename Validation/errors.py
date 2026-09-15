from Validation.elements import Element

def tooManyBondsError(element: Element) -> str:
    return f"Error: too many bonds for {element.name}."

def bondNotYetImplementedError(bondType: str) -> str:
    return f"Error: {bondType} bonding validation hasn't been implemented yet."