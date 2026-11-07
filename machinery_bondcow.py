# I speak in Latin to God, Italian to Women, French to Men, German to my Horse, and in Claude to python.
# - Charles V (disputed)

from rdkit import Chem
from rdkit import RDLogger

# For the formula-counting machinery
from collections import Counter

# If any unparseable molecules are found, the julia code will be notified of this anyway
#   because of the canary var. Therefore we can turn off any console-printing warnings here
RDLogger.DisableLog('rdApp.*')

# Pass strict=False if you suspect your dataset has some quirky bonds somewhere
#   and your code is ready to catch any molecule with a bond tagged 'o' and then
#   maybe write a summary at the end with the odd ones out or something
def bondtype2char(type, strict=True):
    if (type == Chem.BondType.SINGLE):
        return 's'
    elif (type == Chem.BondType.DOUBLE):
        return 'd'
    elif (type == Chem.BondType.TRIPLE):
        return 't'
    elif (type == Chem.BondType.AROMATIC):
        return 'a'
    else:
        if (strict):
            raise ValueError(f"Unknown bond type: {type}")
        else:
            return 'o'  # other

# The zahlen are copied directly, so if you care about their order, you'll have to do this check yourself (personally I ensure that zahl1 <= zahl2 so that it's easy to compare any two bonds)
def getlistbonds(smi):
    try:
        m = Chem.MolFromSmiles(smi)
        if m is None:  # Additional check for invalid SMILES
            return (False, [])

        m = Chem.AddHs(m) # Add hydrogens so the covalent-bonds-containing-hydrogen are counted
        # tsb: tuples containing the bond info
        tsb = []
        for b in m.GetBonds():
            tsb.append( (
                b.GetBeginAtom().GetAtomicNum(),
                b.GetEndAtom().GetAtomicNum(),
                bondtype2char(b.GetBondType(),strict=False)
            ) )
        return (True,tsb)
    except Exception as e:
        return (False, [])

# The zahlen are copied directly, so if you care about their order, you'll have to do this check yourself (personally I ensure that, for a bond, zahl1 <= zahl2 so that it's easy to compare any two bonds)
def getlistatoms(smi):
    try:
        m = Chem.MolFromSmiles(smi)
        if m is None:  # Additional check for invalid SMILES
            return (False, [])

        m = Chem.AddHs(m) # Add hydrogens so the covalent-bonds-containing-hydrogen are counted
        # azs: atom zahlen (I'm using haskell's "suffix s means the
        #      identifier is a vector containing many of the singletons
        #      (in this case, atomzahlen)" notation, I know German
        #      doesn't make plurals by adding an 's' at the end)
        azs = [atom.GetAtomicNum() for atom in m.GetAtoms()]
        return (True,azs)
    except Exception as e:
        return (False, [])

# The atsyms are copied directly, so if you care about their order, you'll have to do this check yourself (personally I ensure that zahl1 <= zahl2 so that it's easy to compare any two bonds), and note that you'll also have to consider the hybridization when sorting the "symbols" (they look like 'C_sp3' and such)
def getlistatoms_hybridization(smi):
    try:
        m = Chem.MolFromSmiles(smi)
        if m is None:  # Additional check for invalid SMILES
            return (False, [])

        m = Chem.AddHs(m) # Add hydrogens so the proportion of H compared to heavy atoms is also reported

        # symhyb looks like this at the end:
        # ["C_sp3", "O_sp3", "C_sp2"]
        symhyb = []
        for atom in m.GetAtoms():
            atomic_num = atom.GetAtomicNum()
            atsym = atom.GetSymbol()
            hybridization = atom.GetHybridization()

            # Map RDKit hybridization to our labels
            if (atomic_num == 1):
                state = "   " # For hydrogen only; it's kinda weird to assign a hybridization to it. So we just add this strut of sorts for alignment in the results table
                symhyb.append(f"{atsym}    ") # Only for hydrogen: append the symbol
                                              #   but skip the subscript (tho add
                                              #   spaces for, well, spacing)
                continue

            elif hybridization == Chem.HybridizationType.SP3:
                state = 'sp3'
            elif hybridization == Chem.HybridizationType.SP2:
                state = 'sp2'
            elif hybridization == Chem.HybridizationType.SP:
                state = 'sp ' # Extra spaces so the formatting is easier
            elif hybridization == Chem.HybridizationType.S:
                state = 's  '
            else:
                state = "unk"

            symhyb.append(f"{atsym}_{state}")

        return (True,symhyb)
    except Exception as e:
        return (False, [])

# getformula("CCO") -> ([1, 6, 8], [6, 2, 1])
# Strict mode is default (it'll reject any molecule where, say, hydrogens have 2 bonds or carbons have 5 bonds)
#   **Use strict mode unless you're certain you need the alternate behavior**
# Lax mode skips sanitization (so it allows smiles where the above happens), then attempts to add hydrogens
# Trust-input mode skips sanitization AND doesn't add hydrogens
def getformula(smi, mode="strict"):
    """
    Return (zahlen, counts), where zahlen contains atomic numbers.

    modes:
      "strict"      Parse and sanitize, then add inferred hydrogens.
      "lax"         Skip sanitization, then attempt to add inferred hydrogens.
      "trust-input" Skip sanitization and count only atoms written in the SMILES.
      "faith"       Alias for "trust-input".
    """
    if mode == "faith":
        mode = "trust-input"
    if mode not in {"strict", "lax", "trust-input"}:
        raise ValueError("mode must be 'strict', 'lax', 'trust-input' or 'faith'")

    params = Chem.SmilesParserParams()
    params.sanitize = (mode == "strict")
    params.removeHs = False  # Keep explicit [H] atoms in the parsed graph.

    mol = Chem.MolFromSmiles(smi, params)
    if mol is None:
        return (False,[0],[0])

    if mode == "strict":
        mol = Chem.AddHs(mol)
    elif mode == "lax":
        # Permit property-cache calculations without strict valence checking.
        mol.UpdatePropertyCache(strict=False)
        mol = Chem.AddHs(mol)

    counts_by_z = Counter(atom.GetAtomicNum() for atom in mol.GetAtoms())

    zahlen = sorted(counts_by_z)
    counts = [counts_by_z[z] for z in zahlen]
    return (True, zahlen, counts)
