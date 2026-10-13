from rdkit import Chem
from rdkit.Chem import AllChem

BOND = {"single": Chem.BondType.SINGLE, "double": Chem.BondType.DOUBLE, "triple": Chem.BondType.TRIPLE}

def generate_3d(m, app_id):
    m3 = Chem.Mol(m)  # copy so we don't mess with the validated one
    if AllChem.EmbedMolecule(m3, randomSeed=42) != 0:
        return None  # RDKit couldn't find a geometry, rare but possible
    if AllChem.MMFFHasAllMoleculeParams(m3):
        AllChem.MMFFOptimizeMolecule(m3)   # best force field for organic stuff
    else:
        AllChem.UFFOptimizeMolecule(m3)    # fallback for elements MMFF doesn't know
    pos = m3.GetConformer().GetPositions()
    center = pos.mean(axis=0)              # center it on (0,0,0)
    return [
        {"atomId": app_id[i], "x": float(p[0] - center[0]), "y": float(p[1] - center[1]), "z": float(p[2] - center[2])}
        for i, p in enumerate(pos)
    ]

def validate_molecule(atoms, bonds):
    mol = Chem.RWMol()
    idx = {}
    for a in atoms:
        atom = Chem.Atom(a.name)
        atom.SetNoImplicit(True)
        atom.SetFormalCharge(a.charge)
        idx[a.idAtom] = mol.AddAtom(atom)
    for b in bonds:
        mol.AddBond(idx[b.idAtom1], idx[b.idAtom2], BOND[b.bondType.value])

    app_id = {v: k for k, v in idx.items()}
    errors = [{"atomId": app_id.get(p.GetAtomIdx()), "message": p.Message()}
              for p in Chem.DetectChemistryProblems(mol)]
    if errors:
        return {"valid": False, "errors": errors}

    m = mol.GetMol()
    Chem.SanitizeMol(m)
    for atom in m.GetAtoms():
        if atom.GetNumRadicalElectrons():
            errors.append({"atomId": app_id[atom.GetIdx()],
                           "message": f"{atom.GetSymbol()} still has open bonds"})
    if errors:
        return {"valid": False, "errors": errors}
    return {"valid": True, "errors": [], "positions": generate_3d(m, app_id)}