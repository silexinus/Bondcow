

# STANDARD PACKAGES. THEY COME PREINSTALLED WITH JULIA
import Pkg # Only used if the user requests installrequirements_bondcow()
import Printf
# THIRD-PARTY PACKAGES. THESE MUST BE INSTALLED WITH Pkg.add()
# Any additional import must be reflected in installrequirements_bondcow() and the README.md file
import PlainCLIArgs
import PyCall
import PeriodicTable

PyCall.@pyinclude("machinery_bondcow.py")

function printhelp_bondcow()
    println("Bondcow's main modes require a filename with smis! There's also a few flags you can pass:")
    println("== Main modes:")
    println(" * -a -> Counts the amount of atoms")
    println(" * -b -> Counts the amount of bonds (default)")
    println(" * -y -> Counts the amount of atoms considering their hYbridization")
    println("      (rather than just C, it counts these separately: C_sp3, C_sp2, C_sp, and so on)")
    println(" * -t -> Counts the tokens (smis and deepsmis are tokenized as chars and bracketed-strings, selfies and groupselfies are tokenized as bracketed-strings")
    println(" * -f -> Counts the molecular formulas")
    println("")
    println("== Example calls:")
    println("Bond mode:")
    println("  \$:julia bondcow.jl smis1-qm9.smi")
    println("  \$:julia bondcow.jl smis1-pc9.smi -b")
    println("Atom mode:")
    println("  \$:julia bondcow.jl gdb11_size1to9.smi -a")
    println("  \$:julia bondcow.jl --atom gdb13_size1to9.smi")
    println("")
    println("== Output file:")
    println("By default, the census is saved to disk following this pattern:")
    println("  bncw-<tag>-<input_stem>.out")
    println("where <tag> is 'b' for bond-mode, 'a' for atom-mode,")
    println("               'y' for hybridization-mode, 't' for token-mode,")
    println("               'f' for formula-mode")
    println("where <input_stem> is the input filename without the period-extension part")
    println("For example,")
    println("  \$:julia bondcow.jl smis1-qm9.smi")
    println("outputs to bncw-b-smis1-qm9.out")
    println("You can override the output filename with, say:")
    println("  \$:julia bondcow.jl smis1-qm9.slf --token -o bncw-t-smis1-qm9-slf.out")
    println("== Other modes:")
    println(" * --file-only -> Census is saved to disk (default)")
    println(" * --stdout    -> Census is saved to disk AND written to stdout")
    println(" * --stdout-only -> Census is only written to stdout")
    println(" * -h -> Print this help message")
    println(" * -r -> Install the required julia packages")
    println(" * -v -> Display local version (MODE IS PENDING)")
    println(" * -V -> Display local and newest versions (MODE IS PENDING)")
    println(" * -u -> Update the program (MODE IS PENDING)")
    println("")
    println("== Alias list:")
    println(" -a --atom --atoms")
    println(" -b --bond --bonds")
    println(" -y --hyb --hybridization")
    println(" -t --token --tokens")
    println(" -f --formula")
    println(" -o --output")
    println(" -p --stdout")
    println(" -h --help")
    println(" -v --version")
    println(" -V --compare-version")
    println(" -r --install-requirements")
    println(" -u --update")
    exit(-1)
end

function printversion_bondcow()
    println("Mode \"print version\" is not ready yet!")
    exit(-1)
end

function compareversion_bondcow()
    println("Mode \"compare version\" is not ready yet!")
    exit(-1)
end

function installrequirements_bondcow()
    Pkg.add(["PlainCLIArgs","PeriodicTable","PyCall"])
    Pkg.precompile() # I think this helps frontloading the downtime due to installing
    exit(0)
end

function selfupdate_bondcow()
    println("Mode \"self update\" is not ready yet!")
    exit(-1)
end

struct BehaviorBondcow
    filemolecs :: String
    fileoutput :: String
    outputdirection :: Symbol
    modeatoms :: Bool
    modebonds :: Bool
    modehybridization :: Bool
    modetokens :: Bool
    modeformula :: Bool
    mfsubmode :: Symbol # modeformulasubmode
    modehelp :: Bool
    modeversion :: Bool
    modecompareversion :: Bool
    moderequirements :: Bool
    modeselfupdate :: Bool
end

function dropextension(filepath :: AbstractString)
    r, e = splitext(filepath)
    isempty(e) && error("file has no extension")
    return r
end

function craftfileoutput(fileinput :: AbstractString, modeatom :: Bool, modebond :: Bool, modehybridization :: Bool, modetoken :: Bool, modeformula :: Bool)
    if modeatom
        tag = 'a'
    elseif modebond
        tag = 'b'
    elseif modehybridization
        tag = 'y'
    elseif modetoken
        tag = 't'
    elseif modeformula
        tag = 'f'
    end

    inputstem = dropextension(fileinput)

    return "bncw-"*tag*"-"*inputstem*".out"
end

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ANY NEW MODE-FLAGS MUST ALSO BE ADDED
#   TO THE BOND-MODE BLOCK!! SINCE IT'S
#   THE DEFAULT MODE BUT A CALL WITH NO
#   EXPLICIT MODE FLAG BUT A NONZERO AMOUNT
#   OF `OTHER' FLAGS LIKE THE OUTPUTDIRECTION
#   ONES, WON'T GET CAUGHT BY THE FIRST BLOCK
#   IN THIS FUNCTION!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
function parseargs(args :: AbstractVector{<:AbstractString})
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ANY NEW MODE-FLAGS MUST ALSO BE ADDED
#   TO THE BOND-MODE BLOCK!! SINCE IT'S
#   THE DEFAULT MODE BUT A CALL WITH NO
#   EXPLICIT MODE FLAG BUT A NONZERO AMOUNT
#   OF `OTHER' FLAGS LIKE THE OUTPUTDIRECTION
#   ONES, WON'T GET CAUGHT BY THE FIRST BLOCK
#   IN THIS FUNCTION!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    # Set defaults
    filemolecs = ""
    fileoutput = ""
    outputdirection = :w # :w (default, write to disk, --file-only), :s (--stdout), :ws (write and print to stdout)
    modeatom = false
    modebond = true
    modehybridization = false
    modetoken = false
    modeformula = false
    mfsubmode = :strict # --strict --lax --trust-input/--faith
    modehelp = false
    modeversion = false
    modecompareversion = false
    moderequirements = false
    modeselfupdate = false

    upeof = false # user passed explicit output filename
    mof = "" # maybe output filename (holds the requested filename, if it exists

    if length(args) == 1 && !startswith(args[1],'-')
        # Default mode is bonds; load defaults instantly if the user
        #   only passed the filename (it's contained in args[1])
        filemolecs = args[1]
        fileoutput = craftfileoutput(filemolecs,modeatom,modebond,modehybridization,modetoken,modeformula)
        return BehaviorBondcow(filemolecs,fileoutput,outputdirection,
                               modeatom,modebond,modehybridization,modetoken,modeformula,mfsubmode,
                               modehelp,modeversion,modecompareversion,
                               moderequirements,modeselfupdate)
    else
        # Reset this to false; if the user passed "-b" or such, it'll
        #   be flipped back to true in a moment
        modebond = false

        ex = "You can only select one mode out of bondcow's three main modes!\n"
        ex *= "The three modes are: atom count, bond count, atom-by-hybridization-type count"
        ex *= "Run\n  \$:julia bondcow.jl -h\n to see the help message"
        PlainCLIArgs.checkgroupexclusivity(args,ex,["-a", "--atom", "--atoms"],
                                                   ["-b", "--bond", "--bonds"],
                                                   ["-y", "--hyb", "--hybridization"],
                                                   ["-t", "--token", "--tokens"],
                                                   ["-f", "--formula"]
                                          )

        ex = "Modes --stdout and --output are mutually incompatible!\n"
        ex *= "I can't write a file to disk in the mode that doesn't writes to disk\n"
        ex *= "Run\n  \$:julia bondcow.jl -h\n to see the help message"
        PlainCLIArgs.checkgroupexclusivity(args,ex,["-o","--output"],
                                                   ["-p", "--stdout"]
                                          )

        ex = "Modes --file-only (default) and --stdout and --stdout-only are mutually incompatible\n"
        ex *= "Run\n  \$:julia bondcow.jl -h\n to see the help message"
        PlainCLIArgs.checkgroupexclusivity(args,ex,["--file-only"],
                                                   ["-p", "--stdout"],
                                                   ["--stdout-only"]
                                          )

        ex  = "The --formula mode has 3 sub-modes!\n"
        ex *= "  --strict is default (sanitize input and add hydrogens)\n"
        ex *= "  --lax skips sanitization and attempts to add hydrogens\n"
        ex *= "  --trust-input skips sanitization and doesn't add hydrogens,\n"
        ex *= "      hence it gets --faith as alias\n"
        ex *= "Use --strict mode (or pass none of these to select it by default)\n"
        ex *= "  unless you're absolutely certain you need one of the alternate modes\n"
        ex *= "Run\n  \$:julia bondcow.jl -h\n to see the help message"
        PlainCLIArgs.checkgroupexclusivity(args,ex,["--strict"],
                                                   ["--lax"],
                                                   ["--trust-input","--faith"]
                                          )

        claimedtokens = PlainCLIArgs.FlagSearchResult[]

        # Resolve modehelp -h --help
        helpdata = PlainCLIArgs.FlagSearchResult[]
        append!(helpdata, PlainCLIArgs.seekflag(args,"-h"))
        append!(helpdata, PlainCLIArgs.seekflag(args,"--help"))
        if !isempty(helpdata)
            modehelp = true
        end
        append!(claimedtokens,helpdata)

        # Resolve modeversion -v --version
        versiondata = PlainCLIArgs.FlagSearchResult[]
        append!(versiondata, PlainCLIArgs.seekflag(args,"-v"))
        append!(versiondata, PlainCLIArgs.seekflag(args,"--version"))
        if !isempty(versiondata)
            modeversion = true
        end
        append!(claimedtokens,versiondata)

        # Resolve modecompareversion -V --compareversion
        compareversiondata = PlainCLIArgs.FlagSearchResult[]
        append!(compareversiondata, PlainCLIArgs.seekflag(args,"-V"))
        append!(compareversiondata, PlainCLIArgs.seekflag(args,"--compare-version"))
        if !isempty(compareversiondata)
            modecompareversion = true
        end
        append!(claimedtokens,compareversiondata)

        # Resolve moderequirements -r --install-requirements
        requirementsdata = PlainCLIArgs.FlagSearchResult[]
        append!(requirementsdata, PlainCLIArgs.seekflag(args,"-r"))
        append!(requirementsdata, PlainCLIArgs.seekflag(args,"--install-requirements"))
        if !isempty(requirementsdata)
            moderequirements = true
        end
        append!(claimedtokens,requirementsdata)

        # Resolve modeselfupdate -u --update
        selfupdatedata = PlainCLIArgs.FlagSearchResult[]
        append!(selfupdatedata, PlainCLIArgs.seekflag(args,"-u"))
        append!(selfupdatedata, PlainCLIArgs.seekflag(args,"--update"))
        if !isempty(selfupdatedata)
            modeselfupdate = true
        end
        append!(claimedtokens,selfupdatedata)

        # Resolve modeatom -a --atom --atoms
        atomdata = PlainCLIArgs.FlagSearchResult[]
        append!(atomdata, PlainCLIArgs.seekflag(args,"-a"))
        append!(atomdata, PlainCLIArgs.seekflag(args,"--atom"))
        append!(atomdata, PlainCLIArgs.seekflag(args,"--atoms"))
        if !isempty(atomdata)
            modeatom = true
        end
        append!(claimedtokens,atomdata)

        # Resolve modehybridization -y --hyb --hybridization
        hybridizationdata = PlainCLIArgs.FlagSearchResult[]
        append!(hybridizationdata, PlainCLIArgs.seekflag(args,"-y"))
        append!(hybridizationdata, PlainCLIArgs.seekflag(args,"--hyb"))
        append!(hybridizationdata, PlainCLIArgs.seekflag(args,"--hybridization"))
        if !isempty(hybridizationdata)
            modehybridization = true
        end
        append!(claimedtokens,hybridizationdata)

        # Resolve modetoken -t --token --tokens
        tokendata = PlainCLIArgs.FlagSearchResult[]
        append!(tokendata, PlainCLIArgs.seekflag(args,"-t"))
        append!(tokendata, PlainCLIArgs.seekflag(args,"--token"))
        append!(tokendata, PlainCLIArgs.seekflag(args,"--tokens"))
        if !isempty(tokendata)
            modetoken = true
        end
        append!(claimedtokens,tokendata)

        # Resolve modeformula -f --formula
        formuladata = PlainCLIArgs.FlagSearchResult[]
        append!(formuladata, PlainCLIArgs.seekflag(args,"-f"))
        append!(formuladata, PlainCLIArgs.seekflag(args,"--formula"))
        if !isempty(formuladata)
            modeformula = true
        end
        append!(claimedtokens,formuladata)

        # Resolve modebond -b --bond --bonds
        # THIS ONE MUST GO AT THE END SINCE IT'S THE DEFAULT MODE!!!
        bonddata = PlainCLIArgs.FlagSearchResult[]
        append!(bonddata, PlainCLIArgs.seekflag(args,"-b"))
        append!(bonddata, PlainCLIArgs.seekflag(args,"--bond"))
        append!(bonddata, PlainCLIArgs.seekflag(args,"--bonds"))
        if !isempty(bonddata)
            modebond = true
        # Revert this to true if the user passed no other mode-flags
        elseif !modebond && !modeatom && !modehybridization && !modetoken && !modeformula &&
               !modehelp && !modeversion && !modecompareversion &&
               !moderequirements && !modeselfupdate
            modebond = true
        end
        append!(claimedtokens,bonddata)

        # Detect modeformula submode
        mfsubmodedata = PlainCLIArgs.FlagSearchResult[]
        if modeformula
            mfsubmodefound = false
            append!(mfsubmodedata, PlainCLIArgs.seekflag(args,"--strict"))
            if !isempty(mfsubmodedata)
                mfsubmode = :strict
                mfsubmodefound = true
            end

            append!(mfsubmodedata, PlainCLIArgs.seekflag(args,"--lax"))
            if !mfsubmodefound && !isempty(mfsubmodedata)
                mfsubmode = :lax
                mfsubmodefound = true
            end

            append!(mfsubmodedata, PlainCLIArgs.seekflag(args,"--trust-input"))
            append!(mfsubmodedata, PlainCLIArgs.seekflag(args,"--faith"))
            if !mfsubmodefound && !isempty(mfsubmodedata)
                mfsubmode = :trustinput
                mfsubmodefound = true
            end
        end

        # Resolve outputdirection --file-only
        fileonlydata = PlainCLIArgs.FlagSearchResult[]
        append!(fileonlydata, PlainCLIArgs.seekflag(args,"--file-only"))
        if !isempty(fileonlydata)
            outputdirection = :w
        end
        append!(claimedtokens,fileonlydata)

        # Resolve outputdirection -p --stdout
        stdoutdata = PlainCLIArgs.FlagSearchResult[]
        append!(stdoutdata, PlainCLIArgs.seekflag(args,"-p"))
        append!(stdoutdata, PlainCLIArgs.seekflag(args,"--stdout"))
        if !isempty(stdoutdata)
            outputdirection = :ws
        end
        append!(claimedtokens,stdoutdata)

        # Resolve outputdirection --stdout-only
        stdoutonlydata = PlainCLIArgs.FlagSearchResult[]
        append!(stdoutonlydata, PlainCLIArgs.seekflag(args,"--stdout-only"))
        if !isempty(stdoutonlydata)
            outputdirection = :s
        end
        append!(claimedtokens,stdoutonlydata)

        # Resolve requested filename -o --output
        outputfilenamedata = PlainCLIArgs.FlagSearchResult[]
        append!(outputfilenamedata, PlainCLIArgs.seekNvaluesof(args,"-o",1))
        append!(outputfilenamedata, PlainCLIArgs.seekNvaluesof(args,"--output",1))
        if !isempty(outputfilenamedata)
            upeof = true
            mof = PlainCLIArgs.getvalue(outputfilenamedata)
        end
        append!(claimedtokens,outputfilenamedata)

        if modeatom || modebond || modehybridization || modetoken || modeformula

            # Fetch the non-flag from ARGS. There's only supposed to be one nonflag
            #   in ARGS, so we can just fetch the value and see if there's only one
            #   unaccounted-for arg in ARGS
            unclaimed = PlainCLIArgs.findunclaimedtokens(args,claimedtokens)
            #@show claimedtokens
            #@show unclaimed

            if PlainCLIArgs.countvalues(unclaimed) != 1
                error("It's mandatory that you pass exactly one filename containing a list of SMILES!")
            elseif length(unclaimed) != 1
                error("It's mandatory that you pass exactly one filename containing a list of SMILES! Or maybe, did you pass a typo flag?")
            else
                filemolecs = PlainCLIArgs.getvalue(unclaimed)
            end

            if upeof
                fileoutput = mof
            else
                fileoutput = craftfileoutput(filemolecs,modeatom,modebond,modehybridization,modetoken,modeformula)
            end

        # All other modes require no filemolecs value
        else
            filemolecs = ""
        end

        # here1 once the filemolecs value is taken cleanly using getallvalues or something,
        #   add a stray flag catcher here!!
    end

    return BehaviorBondcow(filemolecs,fileoutput,outputdirection,
                           modeatom,modebond,modehybridization,modetoken,modeformula,mfsubmode,
                           modehelp,modeversion,modecompareversion,
                           moderequirements,modeselfupdate)
end

struct BondDescription
    zahl1 :: Int
    zahl2 :: Int
    type  :: Char
end

# The formula C3H9N is stored as FormulaDescription( [1,6,7], [9,3,1] )
struct FormulaDescription
    zahlen :: Vector{Int}
    counts :: Vector{Int}
end

# writeslog as in, write slog to disk, not as in writes log to disk
# This function should only run after the bhvr.outputdirection variable has been checked
#   and you've confirmed that the user wants the log saved to disk
function writeslog(bhvr :: BehaviorBondcow, slog :: AbstractVector{<:AbstractString})
    fh = open(bhvr.fileoutput,"w")
    for line in slog
        write(fh,line)
    end
    close(fh)
    return nothing
end

# sym can be :w or :s
# bhvr.outputdirection can be :w or :s or :ws
# This function compares the :w and :s cases directly, and for :ws returns true on both :w and :s
function isdirectionoutput(bhvr :: BehaviorBondcow, sym :: Symbol)
    if bhvr.outputdirection == :ws
        if sym == :w || sym == :s
            return true
        else
            error("Unknown inquired outputdirection-value passed to isdirectionoutput! Sym is $sym")
        end
    elseif bhvr.outputdirection == :w
        if sym == :w
            return true
        elseif sym == :s
            return false
        else
            error("Unknown inquired outputdirection-value passed to isdirectionoutput! Sym is $sym")
        end
    elseif bhvr.outputdirection == :s
        if sym == :s
            return true
        elseif sym == :w
            return false
        else
            error("Unknown inquired outputdirection-value passed to isdirectionoutput! Sym is $sym")
        end
    end
end

function getsortedzahlen(thisbond :: BondDescription)
    (zahl1,zahl2) = (thisbond.zahl1,thisbond.zahl2)
    if zahl1 < zahl2
        return (zahl1,zahl2)
    else
        return (zahl2,zahl1)
    end
end

function getsortedzahlen(thisbond :: Tuple{Integer,Integer,AbstractChar})
    (zahl1,zahl2) = (thisbond[1],thisbond[2])
    if zahl1 < zahl2
        return (zahl1,zahl2)
    else
        return (zahl2,zahl1)
    end
end

# Compares two bonds, but is UNAWARE of wildcards
# Hence, this is quicker than comparing with Base.:(==)
# Values of type BondDescription can be compared even if their zahlen values are swapped
# BondDescription(6,8,'d') == BondDescription(6,8,'d') -> true
# BondDescription(6,8,'d') == BondDescription(8,6,'d') -> true
# BondDescription(6,6,'d') == BondDescription(6,8,'d') -> false
function simplecomparebond(bd1 :: BondDescription, bd2 :: BondDescription)
    # First compare the bond types. If they are the same, compare the zahlen
    if bd1.type != bd2.type
        return false
    else
        (z1bd1,z2bd1) = getsortedzahlen(bd1)
        (z1bd2,z2bd2) = getsortedzahlen(bd2)
        if z1bd1 == z1bd2 && z2bd1 == z2bd2
            return true
        else
            return false
        end
    end
end

function ordinarybond(bd :: BondDescription)
    if bd.zahl1 > 0 && bd.zahl2 > 0 && bd.type != '*'
        return true
    else
        return false
    end
end

# 1) The case above, neither bond has wildcard zahlen nor types
#   Types 2-6 have at least one wildcard zahl:
# 2-6) One bond description has >0 zahlen, but the other has:
#      2) -1 and -1 <- always fulfilled, regardless of the zahlen of the other bond decription
#      3)  0 and  0 <- fulfilled if: both atoms (of the other bond description) are heavy
#      4)  0 and -1 <- fulfilled if: one of the other two atoms is a heavy atom
#      5) >0 and -1 <- fulfilled if: the heavy atom (>0) matches either of the other two atoms
#      6) >0 and  0 <- fulfilled if: the heavy atom matches either of the other two atoms, and the atom that wasn't used in the match is a heavy atom
function comparezahlenwithwildcards(bd1 :: BondDescription, bd2 :: BondDescription)
    (bd1z1,bd1z2) = sort( (bd1.zahl1,bd1.zahl2) )
    (bd2z1,bd2z2) = sort( (bd2.zahl1,bd2.zahl2) )
    # Resolve branch 2: the bond pair always passes the zahl criterion
    if (bd1z1,bd1z2) == (-1,-1) ||
        (bd2z1,bd2z2) == (-1,-1)
        return true
    # Resolve branch 3: both atoms of the non-wildcard bond description must be heavy
    elseif (bd1z1,bd1z2) == (0,0)
        if isatomheavy(bd2z1) && isatomheavy(bd2z2)
            return true
        else
            return false
        end
    elseif (bd2z1,bd2z2) == (0,0)
        if isatomheavy(bd1z1) && isatomheavy(bd1z2)
            return true
        else
            return false
        end

    # Resolve branch 4 (part 1 of 2)
    elseif (bd1z1,bd1z2) == (-1,0)
        if isatomheavy(bd2z1) || isatomheavy(bd2z2)
            return true
        else
            return false
        end
    # Resolve branch 4 (part 2 of 2)
    elseif (bd2z1,bd2z2) == (-1,0)
        if isatomheavy(bd1z1) || isatomheavy(bd1z2)
            return true
        else
            return false
        end

    # Resolve branch 5 (part 1 of 2)
    elseif bd1z1 == -1 && bd1z2 > 0
        if bd1z2 == bd2z1 || bd1z2 == bd2z2
            return true
        else
            return false
        end
    # Resolve branch 5 (part 2 of 2)
    elseif bd2z1 == -1 && bd2z2 > 0
        if bd2z2 == bd1z1 || bd2z2 == bd1z2
            return true
        else
            return false
        end

    # Resolve branch 6 (part 1 of 2)
    elseif bd1z1 == 0 && bd1z2 > 0
        if bd1z2 == bd2z1 
            if isatomheavy(bd2z2)
                return true
            else
                return false
            end
        elseif bd1z2 == bd2z2
            if isatomheavy(bd2z1)
                return true
            else
                return false
            end
        else
            return false
        end
    # Resolve branch 6 (part 2 of 2)
    elseif bd2z1 == 0 && bd2z2 > 0
        if bd2z2 == bd1z1 
            if isatomheavy(bd1z2)
                return true
            else
                return false
            end
        elseif bd2z2 == bd1z2
            if isatomheavy(bd1z1)
                return true
            else
                return false
            end
        else
            return false
        end

    # Finally resolve branch 1
    else
        return bd1z1 == bd2z1 && bd1z2 == bd2z2
    end
end

# There's two types of bond combinations considering the types:
#   1) both are non-wildcard
#   2) one is a wildcard, the other one isn't
function comparetypeswithwildcards(bd1 :: BondDescription, bd2 :: BondDescription)
    # Resolve branch 2: if either has a wildcard type, the type check
    #   always passes
    if bd1.type == '*' || bd2.type == '*'
        return true
    # Resolve branch 1: compare the types directly
    else
        return bd1.type == bd2.type
    end
end

# Compares two bonds, but is AWARE of wildcards
# This is a more complicated function than comparison using simplecomparebond,
#   so use that one if you're certain you're not passing wildcards
# Values of type BondDescription can be compared even if their zahlen values are swapped
# BondDescription(6,8,'d') == BondDescription(6,8,'d') -> true
# BondDescription(6,8,'d') == BondDescription(8,6,'d') -> true
# BondDescription(6,6,'d') == BondDescription(6,8,'d') -> false
function Base.:(==)(bd1 :: BondDescription, bd2 :: BondDescription)
    # Use the simple function if none of the values in the bonds
    #   are wildcards
    if ordinarybond(bd1) && ordinarybond(bd2)
        return simplecomparebond(bd1,bd2)
    end

    # Otherwise, find the type of the bond pair. There's 5 considering only the zahlen,
    #   and 2 considering only the types. See the functions called below for more detail
    resultzahlen = comparezahlenwithwildcards(bd1,bd2)
    resulttypes = comparetypeswithwildcards(bd1,bd2)

    if resultzahlen && resulttypes
        return true
    else
        return false
    end
end

# iom: index of molec. Only used in case a molecule has a bond other than single or double or triple or aromatic
function getlistbonds(smi :: AbstractString, iom :: Integer, anomalybonds :: AbstractVector{<:NTuple{3,Int}})
    # tsb: tuples with the bond information (note that the zahlen are unsorted)
    (canary,tsb) = PyCall.py"getlistbonds"(smi)
    if !canary
        return (false,BondDescription[],anomalybonds)
    else
        nbonds = length(tsb)
        bdescrs = Array{BondDescription}(undef,nbonds)
        for i in 1:nbonds
            iis = tsb[i]
            # python has no char type, so it always returns a string.
            # The `only' call below unpacks the char within that 1-char string
            # I keep telling ya, python is not a serious language
            thisbond = (iis[1],iis[2],only(iis[3])) # iis: int-int-string
            (zahl1,zahl2) = getsortedzahlen(thisbond)
            bdescrs[i] = BondDescription(zahl1,zahl2,thisbond[3])

            # Bonds tagged as 'other' are stored separately
            if thisbond[3] == 'o'
                push!(anomalybonds, (iom,zahl1,zahl2) )
            end
        end

        return (true,bdescrs,anomalybonds)
    end
end

# iom: index of molec. Only used in case a molecule explodes
function getlistatoms(smi :: AbstractString, iom :: Integer)
    # azs is a list of atomzahlen
    (canary,azs) = PyCall.py"getlistatoms"(smi)
    if !canary
        return (false,Int[])
    else
        return (true,azs)
    end
end

# iom: index of molec. Only used in case a molecule explodes
function getlistatoms_hybridization(smi :: AbstractString, iom :: Integer)
    # symhybs is a stringvec like ["C_sp3", "O_sp3", "C_sp2"]
    (canary,symhybs) = PyCall.py"getlistatoms_hybridization"(smi)
    if !canary
        return (false,String[])
    else
        return (true,symhybs)
    end
end

function bdgetindex(bondtypes :: AbstractVector{<:BondDescription}, bd :: BondDescription)
    iobd = 0 # index of bonddescription
    for bt in bondtypes
        iobd += 1
        if bd == bt
            return iobd
        end
    end
    return 0 # Value zero means the element wasn't found in the list
end

function tokengetindex(tokentypes :: AbstractVector{<:AbstractString}, tk :: Union{Integer,AbstractString})
    iot = 0 # index of token
    for knowntoken in tokentypes
        iot += 1
        if tk == knowntoken
            return iot
        end
    end
    return 0 # Value zero means the element wasn't found in the list
end

function Base.:(==)(for1 :: FormulaDescription, for2 :: FormulaDescription)
    return for1.zahlen == for2.zahlen && for1.counts == for2.counts
end

function formulagetindex(formulatypes :: AbstractVector{<:FormulaDescription}, formula :: FormulaDescription)
    iof = 0 # index of formula
    for knownformula in formulatypes
        iof += 1
        if formula == knownformula
            return iof
        end
    end
    return 0 # Value zero means the element wasn't found in the list
end

function atgetindex(attypes :: Union{AbstractVector{<:Integer},AbstractVector{<:AbstractString}}, az :: Union{Integer,AbstractString})
    ioa = 0 # index of atom
    for knownzahl in attypes
        ioa += 1
        if az == knownzahl
            return ioa
        end
    end
    return 0 # Value zero means the element wasn't found in the list
end

function makebondcensus(filemolecs :: AbstractString)
    bondtypes = BondDescription[]
    bondcounts = Int[]
    anomalybonds = NTuple{3,Int}[]
    iom = 0
    nmolecs = 0
    nfailed = 0
    for smi in eachline(filemolecs)
        iom += 1
        nmolecs += 1
        (canary,bdescrs,anomalybonds) = getlistbonds(smi,iom,anomalybonds)
        if !canary
            nfailed += 1
        else
            for bd in bdescrs
                # iobd: index of bonddescription
                iobd = bdgetindex(bondtypes,bd)
                if iobd == 0
                    push!(bondtypes,bd)
                    push!(bondcounts,1)
                else
                    bondcounts[iobd] += 1
                end
            end
        end
    end

    return (bondtypes,bondcounts,nmolecs,nfailed,anomalybonds)
end

function makeatcensus(filemolecs :: AbstractString; modehybridization :: Bool = false)
    if modehybridization
        attypes = String[] # Stores the symhyb of every atom type ("C_sp3" etc
    else
        attypes = Int[] # Stores the zahl of every atom type
    end
    atcounts = Int[]
    iom = 0
    nmolecs = 0
    nfailed = 0
    for smi in eachline(filemolecs)
        iom += 1
        nmolecs += 1
        if modehybridization
            # here1 rename azs to something neutral for ints and strings!
            (canary,azs) = getlistatoms_hybridization(smi,iom)
        else
            (canary,azs) = getlistatoms(smi,iom)
        end
        if !canary
            nfailed += 1
        else
            for az in azs
                # ioa: index of at
                ioa = atgetindex(attypes,az)
                if ioa == 0
                    push!(attypes,az)
                    push!(atcounts,1)
                else
                    atcounts[ioa] += 1
                end
            end
        end
    end

    return (attypes,atcounts,nmolecs,nfailed)
end

function getextension(filename :: AbstractString; strict :: Bool = false)
    ext = splitext(filename)[2]
    strict && isempty(ext) && throw(ArgumentError("Filename $filename has no extension!!"))
    return ext
end

# Splits molecules encoded as smiles or deepsmiles
# That is, most chars are a token except bracket-constructs like [NH2+] or [O-]
function oldsplitsmiles(smi :: AbstractString)
    tokens = String[]
    ibs = false # ibs: we're in a bracketed string
    tkh = "" # token holder (holds a bracketed string)
    if startswith(smi,"# ERROR")
        return (false,String[])
    else
        for char in smi
            if char != '[' && !ibs
                push!(tokens,string(char))
            elseif ibs && char != ']'
                tkh *= char
            elseif char == ']'
                ibs = false
                tkh *= char
                push!(tokens,string(tkh))
                tkh = ""
            elseif char == '['
                ibs = true
                tkh *= char
            end
        end
        return (true,tokens)
    end
end

# Splits molecules encoded as smiles or deepsmiles
# That is, most chars are a token except bracket-constructs like [NH2+] or [O-]
# Reminder, the `organic subset' in SMILES is B C N O P S F Cl Br I
# So all of those can be written without brackets. Hence methane can be simply written
#   as C, whereas silane must be written like [H][Si]([H])([H]) or [SiH4]. Point being,
#   atoms outside this subset must be written with brackets and their hydrogens must
#   be specified in some way.
# And that's why Cl and Br are so annoying; any C or B means the code must be ready
#   to catch a Cl or Br as a token (THEY DON'T HAVE BRACKETS!!) rather than C and l
#   or B and r. And most of the time turns out it's a C or B -_-
function splitsmiles(smi :: AbstractString)
    tokens = String[]
    skipnext = false # For handling the tokens Cl and Br (they're a headache)
    ibs = false # ibs: we're in a bracketed string
    tkh = "" # token holder (holds a bracketed string)
    if startswith(smi,"# ERROR")
        return (false,String[])
    else
        # There's 4 types of tokens in smiles:
        # 1) A lone char, such as: C n N n = # / ( ) 1 2
        # 2) A bracketed token, such as: [CH3] [NH3+] [Fe++]
        # 3) Chlorine (it has no brackets, hence hydrochloric acid is Cl rather than [H][Cl] (note that this one is also valid, but the shorthand is available, but this places chlorine on the same level as the typical organic atoms B/C/N/O, that can be written without brackets, unlike other atoms like metals)
        # 4) Bromine. Same scenario as chlorine; hydrobromic acid can be written simply as Br
        # Types 3 and 4 are a bit of a headache to handle correctly -_-
        smilen = length(smi)
        i = 0
        for char in smi
            i += 1

            if skipnext
                skipnext = false
                continue
            end

            if char == '['
                ibs = true
            end

            if ibs
                if char == ']'
                    ibs = false
                    tkh *= char
                    push!(tokens,string(tkh))
                    tkh = ""
                else
                    tkh *= char
                end
            else
                # This token might be a Cl, handle it accordingly
                if char == 'C'
                    if i < smilen
                        if smi[i+1] == 'l'
                            # Token is bracketless chlorine
                            skipnext = true
                            push!(tokens,"Cl")
                        else
                            # Token is not bracketless chlorine
                            push!(tokens,string(char))
                        end
                    else
                        push!(tokens,string(char))
                    end
                # This token might be a Br, handle it accordingly
                elseif char == 'B'
                    if i < smilen
                        if smi[i+1] == 'r'
                            # Token is bracketless bromine
                            skipnext = true
                            push!(tokens,"Br")
                        else
                            # Token is not bracketless bromine
                            push!(tokens,string(char))
                        end
                    else
                        push!(tokens,string(char))
                    end
                else
                    push!(tokens,string(char))
                end
            end

        end
        return (true,tokens)
    end
end

# Splits molecules encoded as selfies or groupselfies
# That is, all tokens are bracket-constructs like [C] or [=O] or [Ring1] or [Branch1]
function splitselfies(slf :: AbstractString)
    tokens = String[]
    ibs = false # ibs: we're in a bracketed string
    tkh = "" # token holder (holds a bracketed string)
    if startswith(slf,"# ERROR")
        return (false,String[])
    else
        for char in slf
            if char == ']'
                ibs = false
                tkh *= char
                push!(tokens,string(tkh))
                tkh = ""
            elseif char == '['
                ibs = true
                tkh *= char
            else
                tkh *= char
            end
        end
        return (true,tokens)
    end
end

function loadtokenizemolec(filemolecs :: AbstractString)
    ext = getextension(filemolecs)
    if ext == ".smi" || ext == ".deepsmi" || ext == ".dsmi"
        return splitsmiles
    elseif ext == ".slf" || ext == ".gslf" || ext == ".gpslf" || ext == ".selfies" || ext == ".groupselfies"
        return splitselfies
    else
        error("Unknown extension of filemolecs: $filemolecs")
    end
end

function maketokencensus(filemolecs :: AbstractString)
    tokentypes = String[]
    tokencounts = Int[]
    lencounts = Int[]
    longestlen = 0
    iom = 0
    nmolecs = 0
    nfailed = 0
    tokenizemolec = loadtokenizemolec(filemolecs)

    for smi in eachline(filemolecs)
        iom += 1
        nmolecs += 1

        # tokenizemolec is an alias for either splitsmiles or splitselfies
        (canary,tokens) = tokenizemolec(smi)

        if canary
            for tk in tokens
                # iot: index of token
                iot = tokengetindex(tokentypes,tk)
                if iot == 0
                    push!(tokentypes,tk)
                    push!(tokencounts,1)
                else
                    tokencounts[iot] += 1
                end

            end

            # Now log the molecule's length
            lenmolec = length(tokens)
            while lenmolec > longestlen
                longestlen += 1
                push!(lencounts,0)
            end
            lencounts[lenmolec] += 1

        else
            nfailed += 1
        end
    end

    return (tokentypes,tokencounts,lencounts,nmolecs,nfailed)
end

function getmolecformula(smi :: AbstractString, smode :: AbstractString)
    (canary,zahlen,counts) = PyCall.py"getformula"(smi,mode=smode)
    return (canary, FormulaDescription(zahlen,counts) )
end

function makeformulacensus(bhvr :: BehaviorBondcow)
    filemolecs = bhvr.filemolecs
    smode = String(bhvr.mfsubmode)

    formulatypes = FormulaDescription[]
    formulacounts = Int[]
    nmolecs = 0
    nfailed = 0
    for smi in eachline(filemolecs)
        nmolecs += 1
        (canary,formula) = getmolecformula(smi,smode)
        if !canary
            nfailed += 1
        else
            # iof: index of formula
            iof = formulagetindex(formulatypes,formula)
            if iof == 0
                push!(formulatypes,formula)
                push!(formulacounts,1)
            else
                formulacounts[iof] += 1
            end
        end
    end

    return (formulatypes,formulacounts,nmolecs,nfailed)
end

function parseformuladescription(formula :: FormulaDescription)
    zahlen = formula.zahlen
    counts = formula.counts
    syms = getproperty.(PeriodicTable.elements[zahlen],:symbol)

    sf = "" # String formula
    for i in 1:length(syms)
        sf *= syms[i]
        if counts[i] != 1
            sf *= string(counts[i])
        end
    end
    return sf
end

# ifofc: is formula in formulaclass
# So basically, whether the input formula is of the class described in itcf
# ifofc( FormulaDescription( [1,6,8], [8,3,1]), [1,6,8]) == true
# ifofc( FormulaDescription( [1,6,8], [8,3,1]), [1,6,7]) == false
function ifofc(formula :: FormulaDescription, itcf :: AbstractVector{<:Integer})
    return formula.zahlen == itcf
end

# iozif: index of zahl in formula (in its zahlen vector, namely)
# Return 0 if inzahl is not part of the input formula
# You'd normally not run this and get a 0 in return, since you'd use ifofc
#   before running this one
function zahlgetindexinformula(formula :: FormulaDescription, inzahl :: Integer)
    iozif = 0
    zahlen = formula.zahlen
    for zh in zahlen
        iozif += 1
        if zh == inzahl
            return iozif
        end
    end
    return 0
end

function informulaclass_countnha(formula :: FormulaDescription)
    nha = 0
    for i in 1:length(formula.zahlen)
        if formula.zahlen[i] > 1
            nha += formula.counts[i]
        end
    end
    return nha
end

function informulaclass_findmaxnha(formulatypes :: AbstractVector{<:FormulaDescription})
    maxnha = 0
    for formula in formulatypes
        maxnha = max(maxnha,informulaclass_countnha(formula))
    end
    return maxnha
end

# Call the function like this to find the max amount of C across all
#   HC molecules:
#     informulaclass_findmaxatomcount(formulatypes,["H","C"],"C")
# I'm using the term `formula class' to mean `all HC molecules' or `all HCN molecules' and so on
function informulaclass_findmaxatomcount(formulatypes :: AbstractVector{<:FormulaDescription}, tfc :: AbstractVector{<:AbstractString}, thisatom :: AbstractString)
    itfc = sort(sym2zahl(tfc)) # tfc but as an intvec
    ita = sym2zahl(thisatom) # thisatom but as an int

    macif = typemin(Int) # max atomcount across all entries in a given formulaclass
    for formula in formulatypes
        if ifofc(formula,itfc)
            iozif = zahlgetindexinformula(formula,ita)
            macif = max(macif, formula.counts[iozif] )
        end
    end

    if macif == typemin(Int)
        return 0
    else
        return macif
    end
end

# Temp formatting function for floats
# If lpad is true, numbers below 10 get one space on the left side (since this fun is mostly for pctg vals, this helps their alignment)
# This function will be superseded once the alignment package is up, ah well
function qfmt(fval :: AbstractFloat;lpad :: Bool = true)
    if !lpad
        return Printf.@sprintf("%.2f",round(fval;digits=2))
        
    else
        # Do this for positive fvals under 10; negative vals in (-10,0) have the minus sign on the left already
        if fval < 10.0 && fval > 0.0
            return ' '*Printf.@sprintf("%.2f",round(fval;digits=2))
        else
            return Printf.@sprintf("%.2f",round(fval;digits=2))
        end
    end
end

function fmtformulacensus(filemolecs :: AbstractString, formulatypes :: AbstractVector{<:FormulaDescription}, formulacounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer)

    nf = length(formulacounts)
    ndnf = ndigits(nf)
    slog = String[]

    # Count the amount of molecules by nha
    maxnha = informulaclass_findmaxnha(formulatypes)
    ndmaxnha = ndigits(maxnha) # ndigits, for printing
    counts_nha = zeros(Int,maxnha)
    for i in 1:nf
        thisnha = informulaclass_countnha(formulatypes[i])
        if thisnha > 0
            counts_nha[thisnha] += formulacounts[i]
        end
    end
    ndnha = maximum( ndigits.(counts_nha))

    # Print the HC molecules by amount of C
    # Find the max amount of C in all HC molecules
    cfotb = ["H","C"] # Class formula of this block
    icfotb = sym2zahl(cfotb)
    symaxis = "C" # symaxis since it's the symbol of the atom that all of the entries in this class revolve with respect to this symbol
    maxC_HC = informulaclass_findmaxatomcount(formulatypes,cfotb,symaxis)
    ndmaxC_HC = ndigits(maxC_HC) # ndigits, for printing
    # formulacounts of HC-class sorted by C-count
    counts_HC_C = zeros(Int,maxC_HC)
    for i in 1:nf
        if ifofc(formulatypes[i],icfotb)
            iozif = zahlgetindexinformula(formulatypes[i],sym2zahl(symaxis))
            counts_HC_C[formulatypes[i].counts[iozif]] += formulacounts[i]
        end
    end
    ndcHC_C = maximum( ndigits.(counts_HC_C))

    # Print the HCN molecules by amount of N
    # Find the max amount of N in all HCN molecules
    cfotb = ["H","C","N"] # Class formula of this block
    icfotb = sym2zahl(cfotb)
    symaxis = "N" # symaxis since it's the symbol of the atom that all of the entries in this class revolve with respect to this symbol
    maxN_HCN = informulaclass_findmaxatomcount(formulatypes,cfotb,symaxis)
    ndmaxN_HCN = ndigits(maxN_HCN) # ndigits, for printing
    # formulacounts of HCN-class sorted by N-count
    counts_HCN_N = zeros(Int,maxN_HCN)
    for i in 1:nf
        if ifofc(formulatypes[i],icfotb)
            iozif = zahlgetindexinformula(formulatypes[i],sym2zahl(symaxis))
            counts_HCN_N[formulatypes[i].counts[iozif]] += formulacounts[i]
        end
    end
    ndcHCN_N = maxN_HCN > 0 ? maximum( ndigits.(counts_HCN_N)) : 0

    # Print the HCO molecules by amount of O
    # Find the max amount of O in all HCO molecules
    cfotb = ["H","C","O"] # Class formula of this block
    icfotb = sym2zahl(cfotb)
    symaxis = "O" # symaxis since it's the symbol of the atom that all of the entries in this class revolve with respect to this symbol
    maxO_HCO = informulaclass_findmaxatomcount(formulatypes,cfotb,symaxis)
    ndmaxO_HCO = ndigits(maxO_HCO) # ndigits, for printing
    # formulacounts of HCO-class sorted by O-count
    counts_HCO_O = zeros(Int,maxO_HCO)
    for i in 1:nf
        if ifofc(formulatypes[i],icfotb)
            iozif = zahlgetindexinformula(formulatypes[i],sym2zahl(symaxis))
            counts_HCO_O[formulatypes[i].counts[iozif]] += formulacounts[i]
        end
    end
    ndcHCO_O = maxO_HCO > 0 ? maximum( ndigits.(counts_HCO_O)) : 0

    # Print the HCNO molecules by amount of N
    # Find the max amount of N in all HCNO molecules
    cfotb = ["H","C","N","O"] # Class formula of this block
    icfotb = sym2zahl(cfotb)
    symaxis = "N" # symaxis since it's the symbol of the atom that all of the entries in this class revolve with respect to this symbol
    maxN_HCNO = informulaclass_findmaxatomcount(formulatypes,cfotb,symaxis)
    ndmaxN_HCNO = ndigits(maxN_HCNO) # ndigits, for printing
    # formulacounts of HCNO-class sorted by N-count
    counts_HCNO_N = zeros(Int,maxN_HCNO)
    for i in 1:nf
        if ifofc(formulatypes[i],icfotb)
            iozif = zahlgetindexinformula(formulatypes[i],sym2zahl(symaxis))
            counts_HCNO_N[formulatypes[i].counts[iozif]] += formulacounts[i]
        end
    end
    ndcHCNO_N = maxN_HCNO > 0 ? maximum( ndigits.(counts_HCNO_N)) : 0

    # Print the HCNO molecules by amount of O
    # Find the max amount of O in all HCNO molecules
    cfotb = ["H","C","N","O"] # Class formula of this block
    icfotb = sym2zahl(cfotb)
    symaxis = "O" # symaxis since it's the symbol of the atom that all of the entries in this class revolve with respect to this symbol
    maxO_HCNO = informulaclass_findmaxatomcount(formulatypes,cfotb,symaxis)
    ndmaxO_HCNO = ndigits(maxO_HCNO) # ndigits, for printing
    # formulacounts of HCNO-class sorted by O-count
    counts_HCNO_O = zeros(Int,maxO_HCNO)
    for i in 1:nf
        if ifofc(formulatypes[i],icfotb)
            iozif = zahlgetindexinformula(formulatypes[i],sym2zahl(symaxis))
            counts_HCNO_O[formulatypes[i].counts[iozif]] += formulacounts[i]
        end
    end
    ndcHCNO_O = maxO_HCNO > 0 ? maximum( ndigits.(counts_HCNO_O)) : 0

    # Sorts by freq; counts by freq; zahlen by freq
    sbf = sortperm(formulacounts;rev=true)
    cbf = formulacounts[sbf]
    tbf = formulatypes[sbf]
    ptbf = parseformuladescription.(tbf)
    ndcbf = maximum(ndigits.(formulacounts))
    ncptbf = maximum( length.(ptbf) )

    npm_HC = sum(counts_HC_C)
    npm_HCN = sum(counts_HCN_N)
    npm_HCO = sum(counts_HCO_O)
    npm_HCNO = sum(counts_HCNO_N)

    push!(slog,"$filemolecs $nmolecs\n")
    push!(slog,"$nfailed $(round(100.0*nfailed/nmolecs,digits=2))\n")
    push!(slog,"$npm_HC $npm_HCN $npm_HCO $npm_HCNO\n")
    push!(slog,"$(qfmt(100*npm_HC/nmolecs)) $(qfmt(100*npm_HCN/nmolecs)) $(qfmt(100*npm_HCO/nmolecs)) $(qfmt(100*npm_HCNO/nmolecs))\n")
    push!(slog,"\n")

    push!(slog,"== Counts by nha\n")
    push!(slog,"$maxnha\n")
    for i in 1:maxnha
        push!(slog,"$(rpad(i,ndmaxnha,' ')) ; $(lpad(counts_nha[i],ndnha,' ')) $(qfmt(100*counts_nha[i]/nmolecs))\n")
    end
    push!(slog,"\n")

    push!(slog,"== HC-class, sorted by C-count\n")
    push!(slog,"$maxC_HC $(qfmt(100*npm_HC/nmolecs))\n")
    for i in 1:maxC_HC
        push!(slog,"C$(rpad(i,ndmaxC_HC,' ')) ; $(lpad(counts_HC_C[i],ndcHC_C,' ')) $(qfmt(100*counts_HC_C[i]/npm_HC)) $(qfmt(100*counts_HC_C[i]/nmolecs))\n")
    end
    push!(slog,"\n")

    push!(slog,"== HCN-class, sorted by N-count\n")
    push!(slog,"$maxN_HCN $(qfmt(100*npm_HCN/nmolecs))\n")
    for i in 1:maxN_HCN
        push!(slog,"N$(rpad(i,ndmaxN_HCN,' ')) ; $(lpad(counts_HCN_N[i],ndcHCN_N,' ')) $(qfmt(100*counts_HCN_N[i]/npm_HCN)) $(qfmt(100*counts_HCN_N[i]/nmolecs))\n")
    end
    push!(slog,"\n")

    push!(slog,"== HCO-class, sorted by O-count\n")
    push!(slog,"$maxO_HCO $(qfmt(100*npm_HCO/nmolecs))\n")
    for i in 1:maxO_HCO
        push!(slog,"O$(rpad(i,ndmaxO_HCO,' ')) ; $(lpad(counts_HCO_O[i],ndcHCO_O,' ')) $(qfmt(100*counts_HCO_O[i]/npm_HCO)) $(qfmt(100*counts_HCO_O[i]/nmolecs))\n")
    end
    push!(slog,"\n")

    push!(slog,"== HCNO-class, sorted by N-count\n")
    push!(slog,"$maxN_HCNO $(qfmt(100*npm_HCNO/nmolecs))\n")
    for i in 1:maxN_HCNO
        push!(slog,"N$(rpad(i,ndmaxN_HCNO,' ')) ; $(lpad(counts_HCNO_N[i],ndcHCNO_N,' ')) $(qfmt(100*counts_HCNO_N[i]/npm_HCNO)) $(qfmt(100*counts_HCNO_N[i]/nmolecs))\n")
    end
    push!(slog,"\n")

    push!(slog,"== HCNO-class, sorted by O-count\n")
    push!(slog,"$maxO_HCNO $(qfmt(100*npm_HCNO/nmolecs))\n")
    for i in 1:maxO_HCNO
        push!(slog,"O$(rpad(i,ndmaxO_HCNO,' ')) ; $(lpad(counts_HCNO_O[i],ndcHCNO_O,' ')) $(qfmt(100*counts_HCNO_O[i]/npm_HCNO)) $(qfmt(100*counts_HCNO_O[i]/nmolecs))\n")
    end
    push!(slog,"\n")

    push!(slog,"== Frequency list\n")
    push!(slog,"$nf\n")
    for i in 1:nf
        push!(slog,"$(lpad(i,ndnf,' ')) ; $(rpad(ptbf[i],ncptbf,' ')) ; $(lpad(cbf[i],ndcbf,' ')) $(qfmt(100*cbf[i]/nmolecs))\n")
    end

    return slog
end

function outputformulacensus(bhvr :: BehaviorBondcow, formulatypes :: AbstractVector{<:FormulaDescription}, formulacounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer)
    filemolecs = bhvr.filemolecs
    slog = fmtformulacensus(filemolecs,formulatypes,formulacounts,nmolecs,nfailed)

    if isdirectionoutput(bhvr,:w)
        writeslog(bhvr,slog)
    end
    if isdirectionoutput(bhvr,:s)
        print.(slog)
    end
    return nothing
end

function iszahlheavy(zahl :: Integer)
    if zahl == 1
        return false
    else
        return true
    end
end

function isatomheavy(zahl :: Integer)
    if zahl == 1
        return false
    else
        return true
    end
end

# The strip part is to catch hydrogens, which
#   are being returned by the python machinery
#   as "H    " rather than the old "H_   ", since
#   the bare underscore looked a bit out of place
function isatomheavy(sym :: AbstractString)
    if strip(sym) == "H"
        return false
    else
        return true
    end
end

function oldzahl2sym(zahl :: Integer)
    if zahl == 1
        return "H"
    elseif zahl == 2
        return "He"
    elseif zahl == 3
        return "Li"
    elseif zahl == 4
        return "Be"
    elseif zahl == 5
        return "B"
    elseif zahl == 6
        return "C"
    elseif zahl == 7
        return "N"
    elseif zahl == 8
        return "O"
    elseif zahl == 9
        return "F"
    elseif zahl == 10
        return "Ne"
    elseif zahl == 11
        return "Na"
    elseif zahl == 12
        return "Mg"
    elseif zahl == 13
        return "Al"
    elseif zahl == 14
        return "Si"
    elseif zahl == 15
        return "P"
    elseif zahl == 16
        return "S"
    elseif zahl == 17
        return "Cl"
    elseif zahl == 18
        return "Ar"
    else
        # Return the stringified zahl if the zahl has no corresponding symbol
        return string(zahl)
    end
end

function zahl2sym(zahl :: Integer)
    return getfield( PeriodicTable.elements[ zahl ],:symbol)
end

function zahl2sym(zahlen :: AbstractVector{<:Integer})
    return getfield.( PeriodicTable.elements[ zahlen ],:symbol)
end

function sym2zahl(sym :: AbstractString)
    return getfield( PeriodicTable.elements[ Symbol(sym) ],:number)
end

function sym2zahl(syms :: AbstractVector{<:AbstractString})
    return getfield.( PeriodicTable.elements[ Symbol.(syms) ],:number)
end

function resolvebondtype(requestedtype :: AbstractString)
    if requestedtype == "s" ||
       requestedtype == "1"
        return 's'
    elseif requestedtype == "d" ||
           requestedtype == "2"
        return 'd'
    elseif requestedtype == "t" ||
           requestedtype == "3"
        return 't'
    elseif requestedtype == "a"
        return 'a'

    # These values load a wildcard
    # So these effectively mean `any bond'
    elseif requestedtype == "" ||
           requestedtype == "*" ||
           requestedtype == " "
        return '*'
    else
        error("Unknown bond type requested: $requestedtype")
    end
end

# This function is here just to allow the user to pass either a char or a string
#   (the two functions with this name always return a char)
function resolvebondtype(requestedtype :: AbstractChar)
    if requestedtype == 's' ||
       requestedtype == '1'
        return 's'
    elseif requestedtype == 'd' ||
           requestedtype == '2'
        return 'd'
    elseif requestedtype == 't' ||
           requestedtype == '3'
        return 't'
    elseif requestedtype == 'a'
        return 'a'

    # These values load a wildcard
    # So these effectively mean `any bond'
    elseif requestedtype == '*' ||
           requestedtype == ' '
        return '*'
    else
        error("Unknown bond type requested: $requestedtype")
    end
end

function fmtbondcensus(filemolecs :: AbstractString, bondtypes :: AbstractVector{<:BondDescription}, bondcounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer, anomalybonds :: AbstractVector{<:NTuple{3,Int}}; sorted :: Bool = true)
    slog = String[]
    if sorted
        sp = sortperm(bondcounts,rev=true)
        bondtypes = bondtypes[sp]
        bondcounts = bondcounts[sp]
    end

    # Indices of bond types that are hat-hat or otherwise
    ibth = Int[]
    ibtl = Int[]
    i = 0
    for bd in bondtypes
        i += 1
        if iszahlheavy(bd.zahl1) && iszahlheavy(bd.zahl2)
            push!(ibth,i)
        else
            push!(ibtl,i)
        end
    end

    # tbc: total bond count
    tbc = sum(bondcounts)
    tbc_h = sum(bondcounts[ibth])
    tbc_l = sum(bondcounts[ibtl])
    # nbt: n(bondtypes)
    nbt = length(bondtypes)
    nd_nbt = ndigits(nbt)

    # First print the hat-hat bonds; the hat-H bonds go afterwards
    j = 0
    # max n(chars for the hat-hat bond counts)
    nc_nbh = maximum( ndigits.( bondcounts[ibth]) )
    push!(slog,"$filemolecs $nmolecs\n")
    # here1 Oh no I forgot about the easy-formatting functions. I have a few other instances of the round fun being used and I also ought to change those for these quickformatting funs EDIT: I also have the qfmt function in this file; ought to be replaced by a proper quick-formatting function
    push!(slog,"$nfailed $(round(100.0*nfailed/nmolecs,digits=2))\n")
    push!(slog,"$tbc_h $tbc_l $tbc\n")
    push!(slog,"\n")
    push!(slog,"== hat-hat bonds\n")
    push!(slog,"$(length(ibth))\n")
    # The push! below prints: bondtype's index in its class, zahlen of the atoms involved,
    #   a char representing the bond type, how many times the bond appears,
    #   the pctg of this bond type within its class (hat-hat or light-atom),
    #   the pctg of this bond type considering all bond types in the dataset
    for i in 1:nbt
        if i in ibth
            j += 1
            bd = bondtypes[i]
            push!(slog,"$(lpad(j,nd_nbt,' ')) ; $(zahl2sym(bd.zahl1)) $(zahl2sym(bd.zahl2)) $(bd.type) ; $(lpad(bondcounts[i],nc_nbh,' ')) $(lpad(round(100.0*bondcounts[i]/tbc_h,digits=2),5,' ')) $(lpad(round(100.0*bondcounts[i]/tbc,digits=2),5,' '))\n")
        end
    end

    # Now print the light-atom bonds (H-heavy and H-H)
    j = 0
    # max n(chars for the light-atom bond counts)
    nc_nbl = maximum( ndigits.( bondcounts[ibtl]) )
    push!(slog,"\n")
    push!(slog,"== light-atom bonds\n")
    push!(slog,"$(length(ibtl))\n")
    # The push! below prints: bondtype's index in its class, zahlen of the atoms involved,
    #   a char representing the bond type, how many times the bond appears,
    #   the pctg of this bond type within its class (hat-hat or light-atom),
    #   the pctg of this bond type considering all bond types in the dataset
    for i in 1:nbt
        if i in ibtl
            j += 1
            bd = bondtypes[i]
            push!(slog,"$(lpad(j,nd_nbt,' ')) ; $(zahl2sym(bd.zahl1)) $(zahl2sym(bd.zahl2)) $(bd.type) ; $(lpad(bondcounts[i],nc_nbl,' ')) $(lpad(round(100.0*bondcounts[i]/tbc_l,digits=2),5,' ')) $(lpad(round(100.0*bondcounts[i]/tbc,digits=2),5,' '))\n")
        end
    end

    push!(slog,"\n")
    nab = length(anomalybonds)
    push!(slog,"== anomaly bonds\n")
    push!(slog,"$(nab)\n")
    for i in 1:nab
        iom = anomalybonds[i][1]
        sym1 = zahl2sym(anomalybonds[i][2])
        sym2 = zahl2sym(anomalybonds[i][3])
        push!(slog,"$iom $sym1 $sym2\n")
    end

    return slog
end

function fmtatcensus(filemolecs :: AbstractString, atzahlen :: AbstractVector{<:Integer}, atcounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer; sorted :: Bool = true)
    atsyms = zahl2sym(atzahlen)
    return fmtatcensus(filemolecs,atsyms,atcounts,nmolecs,nfailed;sorted=sorted)
end

function fmtatcensus(filemolecs :: AbstractString, attypes :: AbstractVector{<:AbstractString}, atcounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer; sorted :: Bool = true)
    slog = String[]
    if sorted
        sp = sortperm(atcounts,rev=true)
        attypes = attypes[sp]
        atcounts = atcounts[sp]
    end

    # EDIT: I'm going to test out splitting the atsym in the underscore, if there's one
    #       I think a database would normally have some explicit hydrogens; hence I think it's better to
    #       count them separately from the heavy-atom list. Even if for most bases there's barely any hydrogens
    #=
    # If attypes has at least underscore, we're running this function in atoms-by-hybridization mode
    # This means, we have to print one proportion in the table rather than two (because hydrogen would also
    #   be considered a heavy atom since its symhyb (symbol and hybridization) is "H_s  ". Anyway what I'm saying
    #   is that hydrogens would very rarely be mentioned here
    if (any(contains.(attypes,'_')))
    else
    end
    =#

    # Indices of at types that are hats or otherwise
    iath = Int[]
    iatl = Int[] # This vector is supposed to hold at most 1 val (hydrogen's index in attypes)
    i = 0
    for atsym in attypes
        i += 1
        #if (isatomheavy(atsym))
        if isatomheavy(split(atsym,'_')[1]) # <- In case atsym looks like "H_s  ", the split makes it recognizeable as a light atom
            push!(iath,i)
        else
            push!(iatl,i)
        end
    end

    # tac: total atom count
    tac = sum(atcounts)
    tac_h = sum(atcounts[iath])
    tac_l = sum(atcounts[iatl])
    # na: n(attypes)
    na = length(attypes)
    nd_na = ndigits(na)
    na_h = length(iath) # Amount of heavy-atom types

    # First print the hat-hat bonds; the hat-H bonds go afterwards
    j = 0
    # max n(chars for the atom counts)
    nc_na = maximum( ndigits.( atcounts) )
    push!(slog,"$filemolecs $nmolecs\n")
    # here1 Oh no I forgot about the easy-formatting functions. I have a few other instances of the round fun being used and I also ought to change those for these quickformatting funs
    push!(slog,"$nfailed $(round(100.0*nfailed/nmolecs,digits=2))\n")
    push!(slog,"$tac_h $tac_l $tac\n")
    push!(slog,"\n")
    push!(slog,"== atom counts\n")
    push!(slog,"$na\n")

    # The push! below prints: attype's index in its class, its atomzahl
    #   how many times the atom appears,
    #   the pctg of this bond type within its class (only for heavy atoms),
    #   the pctg of this bond type considering all atom types in the dataset
    for i in 1:na
        if i in iath
            j += 1
            # This is how the data used to be fetched, but surely this is wrong? It's taking rows sequentially where they should be instead taken from iath
            #atsym = attypes[i]
            #push!(slog,"$(lpad(j,nd_na,' ')) ; $atsym ; $(lpad(atcounts[i],nc_na,' ')) $(lpad(round(100.0*atcounts[i]/tac_h,digits=2),5,' ')) $(lpad(round(100.0*atcounts[i]/tac,digits=2),5,' '))\n")

            ioa = iath[j]
            atsym = attypes[ioa]
            push!(slog,"$(lpad(j,nd_na,' ')) ; $atsym ; $(lpad(atcounts[ioa],nc_na,' ')) $(lpad(round(100.0*atcounts[ioa]/tac_h,digits=2),5,' ')) $(lpad(round(100.0*atcounts[ioa]/tac,digits=2),5,' '))\n")
        end
    end

    # Now print the hydrogen info
    # This part of the code is NOT ready to handle helium. Hopefully that won't be necessary x_x . Is helium light or heavy??
    # The penultimate `word' has no meaning for hydrogen (it's the fraction-presence of this row's heavy atom), hence
    #   the hardcoded " 0.00" rather than computing a proportion
    # Note that this part is skipped for the atoms-by-hybridization mode
    j = 0
    for i in 1:na
        if i in iatl
            j += 1
            ioa = iatl[j]
            atsym = attypes[ioa]
            push!(slog,"$(lpad(na_h+j,nd_na,' ')) ; $atsym ; $(lpad(atcounts[ioa],nc_na,' '))  0.00 $(lpad(round(100.0*atcounts[ioa]/tac,digits=2),5,' '))\n")
        end
    end

    return slog
end

function outputbondcensus(bhvr :: BehaviorBondcow, bondtypes :: AbstractVector{<:BondDescription}, bondcounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer, anomalybonds :: AbstractVector{<:NTuple{3,Int}}; sorted :: Bool = true)
    filemolecs = bhvr.filemolecs
    slog = fmtbondcensus(filemolecs,bondtypes,bondcounts,nmolecs,nfailed,anomalybonds; sorted=true)

    if isdirectionoutput(bhvr,:w)
        writeslog(bhvr,slog)
    end
    if isdirectionoutput(bhvr,:s)
        print.(slog)
    end
    return nothing
end

# Works for both atomic modes (regular atoms and atoms-by-hybridization)
# The only difference between those two calls is the type of attypes_atzahlen
#   (it's an intvec for regular-atom mode; an svec for atoms-by-hybridization mode)
#   but the fun fmtatcensus converts the ivec to an svec with symbols, so the actual
#   fmtatcensus fun always uses strings to characterize the atom types regardless of
#   the type of attypes_atzahlen that you passed
function outputatcensus(bhvr :: BehaviorBondcow, attypes_atzahlen :: Union{AbstractVector{<:Integer},AbstractVector{<:AbstractString}}, atcounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer; sorted :: Bool = true)
    filemolecs = bhvr.filemolecs
    slog = fmtatcensus(filemolecs,attypes_atzahlen,atcounts,nmolecs,nfailed; sorted=sorted)

    if isdirectionoutput(bhvr,:w)
        writeslog(bhvr,slog)
    end
    if isdirectionoutput(bhvr,:s)
        print.(slog)
    end
    return nothing
end

function fmttokencensus(filemolecs :: AbstractString, tokentypes :: AbstractVector{<:AbstractString}, tokencounts :: AbstractVector{<:Integer}, lencounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer; sorted :: Bool = true)
    slog = String[]
    if sorted
        sp = sortperm(tokencounts,rev=true)
        tokentypes = tokentypes[sp]
        tokencounts = tokencounts[sp]
    end

    # ttc: total token count
    ttc = sum(tokencounts)
    nt = length(tokentypes) # nt: n(tokentypes)
    nd_nt = ndigits(nt)
    nc_t = maximum( length.(tokentypes) ) # max nchars in the token list
    # max n(chars for the atom counts)
    nc_nt = maximum( ndigits.( tokencounts) )

    # tlc: total len count
    tlc = sum(lencounts)
    nl = length(lencounts) # n(lencounts)
    nd_nl = ndigits(nl)
    nc_l = maximum( ndigits.(lencounts) ) # max nchars in the len list

    push!(slog,"$filemolecs $nmolecs\n")
    push!(slog,"$nfailed $(round(100.0*nfailed/nmolecs,digits=2))\n")
    push!(slog,"$ttc\n")
    push!(slog,"\n")
    # here1 Oh no I forgot about the easy-formatting functions. I have a few other instances of the round fun being used and I also ought to change those for these quickformatting funs
    push!(slog,"== token counts\n")
    push!(slog,"$nt\n")

    # The push! below prints: the token's index in the frequency list,
    #   how many times the token appears,
    #   the pctg of this token in the dataset
    for i in 1:nt
        token = rpad(tokentypes[i],nc_t,' ')
        push!(slog,"$(lpad(i,nd_nt,' ')) ; $token ; $(lpad(tokencounts[i],nc_nt,' ')) $(lpad(round(100.0*tokencounts[i]/ttc,digits=2),5,' '))\n")
    end

    push!(slog,"\n")
    push!(slog,"== length counts\n")
    push!(slog,"$nl\n")

    #nd_nl = ndigits(nl)
    #nc_l = maximum( length.(lencounts) ) # max nchars in the len list

    # The push! below prints: the token's index in the frequency list,
    #   how many times the token appears,
    #   the pctg of this token in the dataset
    for i in 1:nl
        push!(slog,"$(lpad(i,nd_nl,' ')) ; $(lpad(lencounts[i],nc_l,' ')) $(lpad(round(100.0*lencounts[i]/tlc,digits=2),5,' '))\n")
    end

    return slog
end

function outputtokencensus(bhvr :: BehaviorBondcow, tokentypes :: AbstractVector{<:AbstractString}, tokencounts :: AbstractVector{<:Integer}, lencounts :: AbstractVector{<:Integer}, nmolecs :: Integer, nfailed :: Integer; sorted :: Bool = true)
    filemolecs = bhvr.filemolecs
    slog = fmttokencensus(filemolecs,tokentypes,tokencounts,lencounts,nmolecs,nfailed; sorted=sorted)

    if isdirectionoutput(bhvr,:w)
        writeslog(bhvr,slog)
    end
    if isdirectionoutput(bhvr,:s)
        print.(slog)
    end
    return nothing
end
