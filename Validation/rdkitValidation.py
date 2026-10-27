import numpy as np
from rdkit import Chem
from rdkit.Chem import AllChem, rdDepictor, rdMolAlign, rdMolTransforms

BOND = {"single": Chem.BondType.SINGLE, "double": Chem.BondType.DOUBLE, "triple": Chem.BondType.TRIPLE}

KJ_PER_KCAL = 4.184
MAX_SHAPES = 5            # don't overwhelm the list
ENERGY_WINDOW_KJ = 35.0   # skip shapes way less stable than the best one (they'd basically never happen)
SAME_SHAPE_RMSD = 0.3     # two shapes closer than this (angstroms, heavy atoms) count as the same shape


def _ring_torsions(conf, ring):
    # the 6 twist angles going around a ring, in degrees
    n = len(ring)
    return [rdMolTransforms.GetDihedralDeg(conf, ring[i], ring[(i + 1) % n], ring[(i + 2) % n], ring[(i + 3) % n])
            for i in range(n)]


def _six_ring_name(mol, conf_id):
    # chair / boat / twist-boat names, but only for molecules with exactly one 6-membered ring
    rings = [r for r in mol.GetRingInfo().AtomRings() if len(r) == 6]
    if len(rings) != 1:
        return None
    t = _ring_torsions(mol.GetConformer(conf_id), rings[0])
    if all(abs(x) < 15 for x in t):
        return "Flat"
    alternating = all(t[i] * t[(i + 1) % 6] < 0 for i in range(6))
    if alternating and all(abs(x) > 30 for x in t):
        return "Chair"
    near_zero = [i for i, x in enumerate(t) if abs(x) < 15]
    if len(near_zero) == 2 and (near_zero[1] - near_zero[0]) == 3:
        return "Boat"
    return "Twist-boat"


def _perspective_diagram(mol, conf_id, app_id, ring):
    # a textbook-style "perspective" drawing of a puckered ring (like the chair and boat drawings):
    # look at the 3D shape almost edge-on, from a little above, and flatten it from there.
    # returns None for flat rings (like benzene), where the normal flat diagram is better.
    pos = mol.GetConformer(conf_id).GetPositions()
    ring_pos = pos[list(ring)]
    if all(abs(t) < 15 for t in _ring_torsions(mol.GetConformer(conf_id), ring)):
        return None
    center = ring_pos.mean(axis=0)
    _, _, axes = np.linalg.svd(ring_pos - center)
    normal = axes[2]  # points straight out of the ring's plane (axes[0] and axes[1] lie in it)

    # textbook chair/boat drawings look across the ring at a right angle to the line between two
    # opposite ring atoms (so one end is the "headrest" and the other the "footrest"), from just a
    # little above. we try each pair of opposite atoms and a few small tilts, and keep the view where
    # the ring's atoms are most spread out (nothing drawn on top of anything else)
    k = len(ring)
    heights = (ring_pos - center) @ normal  # how far each ring atom sticks up/down out of the ring's plane

    # boats and twist-boats have a "bow" and "stern": two opposite atoms that stick out the same way
    # (chairs don't: their opposite atoms always point opposite ways)
    is_boat = any(heights[i] * heights[(i + k // 2) % k] > 0.01 for i in range(k // 2))

    def project(view, ring_normal):
        up = ring_normal - np.dot(ring_normal, view) * view
        up /= np.linalg.norm(up)
        right = np.cross(up, view)
        return np.stack([(pos - center) @ right, (pos - center) @ up], axis=1)

    def ring_gaps(flat):
        pts = flat[list(ring)]
        return min(np.linalg.norm(pts[a] - pts[b]) for a in range(k) for b in range(a + 1, k))

    best = None
    if is_boat:
        # textbook boat / twist-boat drawings: almost edge-on, a long low hull (about 3x wider than tall)
        # whose closest bond runs flat across the front. we sweep all the way around the ring and keep
        # the widest, lowest view where no two ring atoms sit on each other (the front bond gets
        # leveled afterwards, see below)
        in_plane_1, in_plane_2 = axes[0], axes[1]
        for ring_normal in (normal, -normal):
            for degrees in range(0, 360, 2):
                a = np.radians(degrees)
                sideways = np.cos(a) * in_plane_1 + np.sin(a) * in_plane_2
                for tilt_degrees in (6,):
                    tilt = np.radians(tilt_degrees)
                    view = np.cos(tilt) * sideways + np.sin(tilt) * ring_normal
                    flat = project(view, ring_normal)
                    pts = flat[list(ring)]
                    wide_and_low = np.ptp(pts[:, 0]) / max(np.ptp(pts[:, 1]), 1e-6)
                    readable = ring_gaps(flat) > 0.25
                    score = (readable, wide_and_low if readable else ring_gaps(flat))
                    if best is None or score > best[0]:
                        best = (score, flat, view)

        # a real edge-on twist-boat's front bond slants ~12 degrees, but textbooks draw it level.
        # like they do, we shear the drawing: slide each point up/down by how far left/right it is.
        # that levels the front bond while vertical lines (the axial H's) stay perfectly vertical
        flat, view = best[1].copy(), best[2]
        depth = (pos - center) @ view
        front = max(range(k), key=lambda j: depth[ring[j]] + depth[ring[(j + 1) % k]])
        a_pt, b_pt = flat[ring[front]], flat[ring[(front + 1) % k]]
        if abs(b_pt[0] - a_pt[0]) > 1e-6:
            slope = (b_pt[1] - a_pt[1]) / (b_pt[0] - a_pt[0])
            flat[:, 1] -= slope * flat[:, 0]
        best = (best[0], flat, view)
    else:
        # textbook chair drawings: look across the ring at a right angle to the line between two opposite
        # ring atoms (so one end is the "headrest" and the other the "footrest"), almost edge-on
        for i in range(k):
            across = ring_pos[(i + k // 2) % k] - ring_pos[i]
            across -= np.dot(across, normal) * normal
            if np.linalg.norm(across) < 1e-6:
                continue
            across /= np.linalg.norm(across)
            sideways = np.cross(normal, across)
            tilt = np.radians(8)
            for side in (1, -1):                                  # from the front or the back
                view = side * np.cos(tilt) * sideways + np.sin(tilt) * normal
                flat = project(view, normal)
                score = ring_gaps(flat)                           # least overlap
                if best is None or score > best[0] + 1e-6:
                    best = (score, flat, view)
    flat = best[1] - best[1].mean(axis=0)
    # how close each atom is to you (bigger = closer). the app draws the closest bonds thicker,
    # like the bold front edge in textbook chair drawings, which is what makes them look 3D
    depth = (pos - center) @ best[2]  # `view` points from the molecule toward you

    ring_set = set(ring)  # only the ring's own bonds get the bold front edge, like textbook drawings
    lewis = [{"atomId": app_id[i], "x": float(flat[i][0]), "y": float(flat[i][1]), "depth": float(depth[i]),
              "inRing": i in ring_set}
             for i in range(mol.GetNumAtoms())]
    skeletal = []
    for atom in mol.GetAtoms():
        if atom.GetAtomicNum() == 1:
            continue  # bond-line drawings leave out the H's
        i = atom.GetIdx()
        h_count = sum(1 for n in atom.GetNeighbors() if n.GetAtomicNum() == 1)
        skeletal.append({"atomId": app_id[i], "x": float(flat[i][0]), "y": float(flat[i][1]),
                         "depth": float(depth[i]), "hydrogens": h_count, "inRing": i in ring_set})
    return {"lewis": lewis, "skeletal": skeletal}


def generate_conformers(m, app_id, attempts=30):
    # finds the different stable 3D shapes (conformers) the molecule can take, most stable first.
    # how: make lots of starting guesses, let the force field relax each one "downhill" into a stable
    # shape, then group the results that ended up as the same shape and keep one of each.
    m3 = Chem.Mol(m)  # copy so we don't mess with the validated one
    params = AllChem.ETKDGv3()
    params.randomSeed = 42  # same answer every time for the same molecule
    conf_ids = list(AllChem.EmbedMultipleConfs(m3, numConfs=attempts, params=params))
    if not conf_ids:
        return []  # RDKit couldn't find any geometry (e.g. a shape too strained to exist)
    if AllChem.MMFFHasAllMoleculeParams(m3):
        results = AllChem.MMFFOptimizeMoleculeConfs(m3, maxIters=2000)  # best force field for organic stuff
    else:
        results = AllChem.UFFOptimizeMoleculeConfs(m3, maxIters=2000)   # fallback for elements MMFF doesn't know
    energies = {cid: results[i][1] * KJ_PER_KCAL for i, cid in enumerate(conf_ids)}
    order = sorted(conf_ids, key=lambda cid: energies[cid])
    best_energy = energies[order[0]]

    # compare shapes using only the heavy atoms (C, O, N...), allowing for symmetry,
    # so e.g. the two mirror-image chairs of cyclohexane count as one shape
    heavy = Chem.RemoveHs(m3)
    if heavy.GetNumAtoms() < 3:
        order = order[:1]  # 1-2 heavy atoms (water, H2...) can only have one shape

    # a mirror-image copy of every shape, so a left-handed and right-handed version of the
    # same shape (like butane's two gauche forms) count as one shape too
    mirror = Chem.Mol(heavy)
    for conf in mirror.GetConformers():
        for i in range(mirror.GetNumAtoms()):
            p = conf.GetAtomPosition(i)
            conf.SetAtomPosition(i, (-p.x, p.y, p.z))

    def same_shape(cid, kept_id):
        return (rdMolAlign.GetBestRMS(heavy, heavy, prbId=cid, refId=kept_id) < SAME_SHAPE_RMSD or
                rdMolAlign.GetBestRMS(mirror, heavy, prbId=cid, refId=kept_id) < SAME_SHAPE_RMSD)

    kept = []
    for cid in order:
        if energies[cid] - best_energy > ENERGY_WINDOW_KJ or len(kept) >= MAX_SHAPES:
            break
        if any(same_shape(cid, k) for k in kept):
            continue  # same shape as one we already have (or its mirror image)
        kept.append(cid)

    # line every shape up with the most stable one (by the heavy atoms), so switching shapes in the
    # app only changes the shape instead of also spinning the whole molecule around
    heavy_ids = [a.GetIdx() for a in m3.GetAtoms() if a.GetAtomicNum() > 1]
    if len(kept) > 1:
        align_ids = heavy_ids if len(heavy_ids) >= 3 else None  # None = use every atom
        rdMolAlign.AlignMolConformers(m3, atomIds=align_ids, confIds=kept)

    # molecules with a puckered ring (5-7 atoms) get a perspective drawing for each shape,
    # so the diagrams show the chair / boat / etc. instead of the same flat polygon every time
    puckerable = [r for r in m3.GetRingInfo().AtomRings() if 5 <= len(r) <= 7]
    main_ring = max(puckerable, key=len) if puckerable else None

    shapes = []
    for number, cid in enumerate(kept, start=1):
        pos = m3.GetConformer(cid).GetPositions()
        center = pos.mean(axis=0)  # center it on (0,0,0)
        relative = energies[cid] - best_energy
        shapes.append({
            "name": _six_ring_name(m3, cid) or f"Shape {number}",
            "diagram": _perspective_diagram(m3, cid, app_id, main_ring) if main_ring else None,  # None = use the normal flat diagram
            "relativeEnergy": round(float(relative), 1),  # kJ/mol above the most stable shape
            "positions": [
                {"atomId": app_id[i], "x": float(p[0] - center[0]), "y": float(p[1] - center[1]), "z": float(p[2] - center[2])}
                for i, p in enumerate(pos)
            ],
        })
    # if two shapes got the same ring name (e.g. two twist-boats), number them so they're tellable apart
    names = [sh["name"] for sh in shapes]
    seen = {}
    for sh in shapes:
        base = sh["name"]
        if names.count(base) > 1:
            seen[base] = seen.get(base, 0) + 1
            sh["name"] = f"{base} {seen[base]}"
    return shapes


def _centered_points(mol, app_ids, include_hydrogen_counts=False):
    # 2D coordinates for every atom, shifted so the diagram is centered on (0, 0)
    pos = mol.GetConformer().GetPositions()
    center = pos.mean(axis=0)
    points = []
    for atom, p in zip(mol.GetAtoms(), pos):
        point = {"atomId": app_ids[atom.GetIdx()], "x": float(p[0] - center[0]), "y": float(p[1] - center[1])}
        if include_hydrogen_counts:
            point["hydrogens"] = atom.GetTotalNumHs()  # e.g. 1 for O in an OH group, so the app can write "OH"
        points.append(point)
    return points

def _mark_straight_carbons(points, mol, app_ids):
    # in a bond-line drawing carbons are just corners, so a carbon in a straight line (like the middle C in
    # C=C=C or C#C-C) has no corner and seems to disappear. textbooks put a small dot there; we flag those
    # carbons so the app can do the same
    spot = {p["atomId"]: np.array([p["x"], p["y"]]) for p in points}
    for atom, point in zip(mol.GetAtoms(), points):
        point["straight"] = False
        if atom.GetSymbol() != "C":
            continue
        neighbors = [app_ids[n.GetIdx()] for n in atom.GetNeighbors() if n.GetAtomicNum() > 1]
        if len(neighbors) != 2 or any(n not in spot for n in neighbors):
            continue
        a = spot[neighbors[0]] - spot[point["atomId"]]
        b = spot[neighbors[1]] - spot[point["atomId"]]
        cos = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9)
        point["straight"] = bool(cos < -0.985)  # within ~10 degrees of a straight line
    return points


def generate_diagrams(m, app_id):
    # Lewis structure: every atom (including H) laid out flat
    lewis = Chem.Mol(m)
    rdDepictor.Compute2DCoords(lewis)

    # bond-line structure: hydrogens removed, carbons become corners of the zigzag
    skeletal = Chem.Mol(m)
    for atom in skeletal.GetAtoms():
        atom.SetIntProp("appId", app_id[atom.GetIdx()])  # remember the app's id, since removing Hs renumbers atoms
    skeletal = Chem.RemoveHs(skeletal)
    rdDepictor.Compute2DCoords(skeletal)
    skeletal_ids = {a.GetIdx(): a.GetIntProp("appId") for a in skeletal.GetAtoms()}

    return {
        "lewis": _centered_points(lewis, app_id),
        "skeletal": _mark_straight_carbons(
            _centered_points(skeletal, skeletal_ids, include_hydrogen_counts=True), skeletal, skeletal_ids),
    }

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
    shapes = generate_conformers(m, app_id)
    return {
        "valid": True,
        "errors": [],
        "positions": shapes[0]["positions"] if shapes else None,  # the most stable shape (what the app snaps to)
        "conformers": shapes,                                       # every distinct shape, most stable first
        "diagram": generate_diagrams(m, app_id),
    }