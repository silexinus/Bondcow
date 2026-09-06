
import Pkg # Only used if the user requests installrequirements_bondcow()
# Any additional import must be reflected in installrequirements_bondcow() and the README.md file
import PlainCLIArgs
import PyCall


PyCall.@pyinclude("machinery_bondcow.py")

function printhelp_bondcow()
    println("Bondcow's main modes require a filename with smis! There's also a few flags you can pass:")
    println("== Main modes:")
    println(" * -a -> Counts the amount of atoms")
    println(" * -b -> Counts the amount of bonds (default)")
    println(" * -y -> Counts the amount of atoms considering their hYbridization")
    println("      (rather than just C, it counts these separately: C_sp3, C_sp2, C_sp, and so on)")
    println("")
    println("== Example calls:")
    println("Bond mode:")
    println("  \$:julia bondcow.jl smis1-qm9.smi")
    println("  \$:julia bondcow.jl smis1-pc9.smi -b")
    println("Atom mode:")
    println("  \$:julia bondcow.jl gdb11_size1to9.smi -a")
    println("  \$:julia bondcow.jl --atom gdb13_size1to9.smi")
    println("Save the output to disk by doing, for example:")
    println("  \$:julia bondcow.jl --atom gdb13_size1to9.smi > bncw-a-gdb13_size1to9.smi")
    println("")
    println("== Other modes:")
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
    Pkg.add(["PlainCLIArgs","PyCall"])
    Pkg.precompile() # I think this helps frontloading the downtime due to installing
    exit(0)
end

function selfupdate_bondcow()
    println("Mode \"self update\" is not ready yet!")
    exit(-1)
end

struct BehaviorBondcow
    filesmis :: String
    modeatoms :: Bool
    modebonds :: Bool
    modehybridization :: Bool
    modehelp :: Bool
    modeversion :: Bool
    modecompareversion :: Bool
    moderequirements :: Bool
    modeselfupdate :: Bool
end

function loadbehavior_bondcow(args :: AbstractVector{<:AbstractString})
    # Set defaults
    filesmis = ""
    modeatom = false
    modebond = true
    modehybridization = false
    modehelp = false
    modeversion = false
    modecompareversion = false
    moderequirements = false
    modeselfupdate = false

    if length(args) == 1 && !startswith(args[1],'-')
        # Default mode is bonds; load defaults instantly if the user
        #   only passed the filename (it's contained in args[1])
        return BehaviorBondcow(args[1],
                               modeatom,modebond,modehybridization,
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
                                                   ["-y", "--hyb", "--hybridization"]
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

        # Resolve modebond -b --bond --bonds
        bonddata = PlainCLIArgs.FlagSearchResult[]
        append!(bonddata, PlainCLIArgs.seekflag(args,"-b"))
        append!(bonddata, PlainCLIArgs.seekflag(args,"--bond"))
        append!(bonddata, PlainCLIArgs.seekflag(args,"--bonds"))
        if !isempty(bonddata)
            modebond = true
        end
        append!(claimedtokens,bonddata)

        # Resolve modehybridization -y --hyb --hybridization
        hybridizationdata = PlainCLIArgs.FlagSearchResult[]
        append!(hybridizationdata, PlainCLIArgs.seekflag(args,"-y"))
        append!(hybridizationdata, PlainCLIArgs.seekflag(args,"--hyb"))
        append!(hybridizationdata, PlainCLIArgs.seekflag(args,"--hybridization"))
        if !isempty(hybridizationdata)
            modehybridization = true
        end
        append!(claimedtokens,hybridizationdata)

        if modeatom || modebond || modehybridization
            # Fetch the non-flag from ARGS. There's only supposed to be one nonflag
            #   in ARGS, so we can just fetch the value and see if there's only one
            #   unaccounted-for arg in ARGS
            # here1 Once PlainCLIArgs.jl gets the getallvals/getallvalues function, I should rework this part
            filesmis = only(PlainCLIArgs.parseargs(args).vals)
        # All other modes require no filesmis value
        else
            filesmis = ""
        end

        # here1 once the filesmis value is taken cleanly using getallvalues or something,
        #   add a stray flag catcher here!!
    end

    return BehaviorBondcow(filesmis,
                           modeatom,modebond,modehybridization,
                           modehelp,modeversion,modecompareversion,
                           moderequirements,modeselfupdate)
end

struct BondDescription
    zahl1 :: Int
    zahl2 :: Int
    type  :: Char
end

function getsortedzahlen(thisbond :: BondDescription)
    (zahl1,zahl2) = (thisbond.zahl1,thisbond.zahl2)
    if (zahl1 < zahl2)
        return (zahl1,zahl2)
    else
        return (zahl2,zahl1)
    end
end

function getsortedzahlen(thisbond :: Tuple{Integer,Integer,AbstractChar})
    (zahl1,zahl2) = (thisbond[1],thisbond[2])
    if (zahl1 < zahl2)
        return (zahl1,zahl2)
    else
        return (zahl2,zahl1)
    end
end

# Values of type BondDescription can be compared even if their zahlen values are swapped
# BondDescription(6,8,'d') == BondDescription(6,8,'d') -> true
# BondDescription(6,8,'d') == BondDescription(8,6,'d') -> true
# BondDescription(6,6,'d') == BondDescription(6,8,'d') -> false
function Base.:(==)(bd1 :: BondDescription, bd2 :: BondDescription)
    # First compare the bond types. If they are the same, compare the zahlen
    if (bd1.type != bd2.type)
        return false
    else
        (z1bd1,z2bd1) = getsortedzahlen(bd1)
        (z1bd2,z2bd2) = getsortedzahlen(bd2)
        if (z1bd1 == z1bd2 && z2bd1 == z2bd2)
            return true
        else
            return false
        end
    end
end

# iom: index of molec. Only used in case a molecule has a bond other than single or double or triple or aromatic
function getlistbonds(smi :: AbstractString, iom :: Integer, anomalybonds :: AbstractVector{<:NTuple{3,Int}})
    # tsb: tuples with the bond information (note that the zahlen are unsorted)
    (canary,tsb) = PyCall.py"getlistbonds"(smi)
    if (!canary)
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
            if (thisbond[3] == 'o')
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
    if (!canary)
        return (false,Int[])
    else
        return (true,azs)
    end
end

# iom: index of molec. Only used in case a molecule explodes
function getlistatoms_hybridization(smi :: AbstractString, iom :: Integer)
    # symhybs is a stringvec like ["C_sp3", "O_sp3", "C_sp2"]
    (canary,symhybs) = PyCall.py"getlistatoms_hybridization"(smi)
    if (!canary)
        return (false,String[])
    else
        return (true,symhybs)
    end
end

function bdgetindex(bondtypes :: AbstractVector{<:BondDescription}, bd :: BondDescription)
    iobd = 0 # index of bonddescription
    for bt in bondtypes
        iobd += 1
        if (bd == bt)
            return iobd
        end
    end
    return 0 # Value zero means the element wasn't found in the list
end

function atgetindex(attypes :: Union{AbstractVector{<:Integer},AbstractVector{<:AbstractString}}, az :: Union{Integer,AbstractString})
    ioa = 0 # index of atom
    for knownzahl in attypes
        ioa += 1
        if (az == knownzahl)
            return ioa
        end
    end
    return 0 # Value zero means the element wasn't found in the list
end

function makebondcensus(filesmis :: AbstractString)
    bondtypes = BondDescription[]
    bondcounts = Int[]
    anomalybonds = NTuple{3,Int}[]
    iom = 0
    nsmis = 0
    nfailed = 0
    for smi in eachline(filesmis)
        iom += 1
        nsmis += 1
        (canary,bdescrs,anomalybonds) = getlistbonds(smi,iom,anomalybonds)
        if (!canary)
            nfailed += 1
        else
            for bd in bdescrs
                # iobd: index of bonddescription
                iobd = bdgetindex(bondtypes,bd)
                if (iobd == 0)
                    push!(bondtypes,bd)
                    push!(bondcounts,1)
                else
                    bondcounts[iobd] += 1
                end
            end
        end
    end

    return (bondtypes,bondcounts,nsmis,nfailed,anomalybonds)
end

function makeatcensus(filesmis :: AbstractString; modehybridization :: Bool = false)
    if (modehybridization)
        attypes = String[] # Stores the symhyb of every atom type ("C_sp3" etc
    else
        attypes = Int[] # Stores the zahl of every atom type
    end
    atcounts = Int[]
    iom = 0
    nsmis = 0
    nfailed = 0
    for smi in eachline(filesmis)
        iom += 1
        nsmis += 1
        if (modehybridization)
            # here1 rename azs to something neutral for ints and strings!
            (canary,azs) = getlistatoms_hybridization(smi,iom)
        else
            (canary,azs) = getlistatoms(smi,iom)
        end
        if (!canary)
            nfailed += 1
        else
            for az in azs
                # ioa: index of at
                ioa = atgetindex(attypes,az)
                if (ioa == 0)
                    push!(attypes,az)
                    push!(atcounts,1)
                else
                    atcounts[ioa] += 1
                end
            end
        end
    end

    return (attypes,atcounts,nsmis,nfailed)
end

function iszahlheavy(zahl :: Integer)
    if (zahl == 1)
        return false
    else
        return true
    end
end

function isatomheavy(zahl :: Integer)
    if (zahl == 1)
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
    if (strip(sym) == "H")
        return false
    else
        return true
    end
end

function zahl2sym(zahl :: Integer)
    if (zahl == 1)
        return "H"
    elseif (zahl == 2)
        return "He"
    elseif (zahl == 3)
        return "Li"
    elseif (zahl == 4)
        return "Be"
    elseif (zahl == 5)
        return "B"
    elseif (zahl == 6)
        return "C"
    elseif (zahl == 7)
        return "N"
    elseif (zahl == 8)
        return "O"
    elseif (zahl == 9)
        return "F"
    elseif (zahl == 10)
        return "Ne"
    elseif (zahl == 11)
        return "Na"
    elseif (zahl == 12)
        return "Mg"
    elseif (zahl == 13)
        return "Al"
    elseif (zahl == 14)
        return "Si"
    elseif (zahl == 15)
        return "P"
    elseif (zahl == 16)
        return "S"
    elseif (zahl == 17)
        return "Cl"
    elseif (zahl == 18)
        return "Ar"
    else
        # Return the stringified zahl if the zahl has no corresponding symbol
        return string(zahl)
    end
end

function fmtbondcensus(filesmis :: AbstractString, bondtypes :: AbstractVector{<:BondDescription}, bondcounts :: AbstractVector{<:Integer}, nsmis :: Integer, nfailed :: Integer, anomalybonds :: AbstractVector{<:NTuple{3,Int}}; sorted :: Bool = true)
    slog = String[]
    if (sorted)
        sp = sortperm(bondcounts,rev=true)
        bondtypes = bondtypes[sp]
        bondcounts = bondcounts[sp]
    end
    #@show bondcounts
    #@show bondtypes

    # Indices of bond types that are hat-hat or otherwise
    ibth = Int[]
    ibtl = Int[]
    i = 0
    for bd in bondtypes
        i += 1
        if (iszahlheavy(bd.zahl1) && iszahlheavy(bd.zahl2))
            push!(ibth,i)
        else
            push!(ibtl,i)
        end
    end
    #@show ibth
    #@show ibtl

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
    push!(slog,"$filesmis $(nsmis+nfailed)\n")
    push!(slog,"$tbc_h $tbc_l $tbc\n")
    # here1 Oh no I forgot about the easy-formatting functions. I have a few other instances of the round fun being used and I also ought to change those for these quickformatting funs
    push!(slog,"$nfailed $(round(100.0*nfailed/nsmis,digits=2))\n")
    push!(slog,"\n")
    push!(slog,"== hat-hat bonds\n")
    push!(slog,"$(length(ibth))\n")
    # The push! below prints: bondtype's index in its class, zahlen of the atoms involved,
    #   a char representing the bond type, how many times the bond appears,
    #   the pctg of this bond type within its class (hat-hat or light-atom),
    #   the pctg of this bond type considering all bond types in the dataset
    for i in 1:nbt
        if (i in ibth)
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
        if (i in ibtl)
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

function fmtatcensus(filesmis :: AbstractString, atzahlen :: AbstractVector{<:Integer}, atcounts :: AbstractVector{<:Integer}, nsmis :: Integer, nfailed :: Integer; sorted :: Bool = true)
    atsyms = zahl2sym.(atzahlen)
    return fmtatcensus(filesmis,atsyms,atcounts,nsmis,nfailed;sorted=sorted)
end

function fmtatcensus(filesmis :: AbstractString, attypes :: AbstractVector{<:AbstractString}, atcounts :: AbstractVector{<:Integer}, nsmis :: Integer, nfailed :: Integer; sorted :: Bool = true)
    slog = String[]
    if (sorted)
        sp = sortperm(atcounts,rev=true)
        attypes = attypes[sp]
        atcounts = atcounts[sp]
    end
    #@show atcounts
    #@show attypes

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
        if (isatomheavy(split(atsym,'_')[1])) # <- In case atsym looks like "H_s  ", the split makes it recognizeable as a light atom
            push!(iath,i)
        else
            push!(iatl,i)
        end
    end
    #@show iath
    #@show iatl

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
    push!(slog,"$filesmis $(nsmis+nfailed)\n")
    push!(slog,"$tac_h $tac_l $tac\n")
    # here1 Oh no I forgot about the easy-formatting functions. I have a few other instances of the round fun being used and I also ought to change those for these quickformatting funs
    push!(slog,"$nfailed $(round(100.0*nfailed/nsmis,digits=2))\n")
    push!(slog,"\n")
    push!(slog,"== atom counts\n")
    push!(slog,"$na\n")
    # The push! below prints: attype's index in its class, its atomzahl
    #   how many times the atom appears,
    #   the pctg of this bond type within its class (only for heavy atoms),
    #   the pctg of this bond type considering all atom types in the dataset
    for i in 1:na
        if (i in iath)
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
        if (i in iatl)
            j += 1
            ioa = iatl[j]
            atsym = attypes[ioa]
            push!(slog,"$(lpad(na_h+j,nd_na,' ')) ; $atsym ; $(lpad(atcounts[ioa],nc_na,' '))  0.00 $(lpad(round(100.0*atcounts[ioa]/tac,digits=2),5,' '))\n")
        end
    end

    return slog
end

function printbondcensus(filesmis :: AbstractString, bondtypes :: AbstractVector{<:BondDescription}, bondcounts :: AbstractVector{<:Integer}, nsmis :: Integer, nfailed :: Integer, anomalybonds :: AbstractVector{<:NTuple{3,Int}}; sorted :: Bool = true)
    slog = fmtbondcensus(filesmis,bondtypes,bondcounts,nsmis,nfailed,anomalybonds; sorted=true)
    print.(slog)
    return nothing
end

# Works for both atomic modes (regular atoms and atoms-by-hybridization)
# The only difference between those two calls is the type of attypes_atzahlen
#   (it's an intvec for regular-atom mode; an svec for atoms-by-hybridization mode)
#   but the fun fmtatcensus converts the ivec to an svec with symbols, so the actual
#   fmtatcensus fun always uses strings to characterize the atom types regardless of
#   the type of attypes_atzahlen that you passed
function printatcensus(filesmis :: AbstractString, attypes_atzahlen :: Union{AbstractVector{<:Integer},AbstractVector{<:AbstractString}}, atcounts :: AbstractVector{<:Integer}, nsmis :: Integer, nfailed :: Integer; sorted :: Bool = true)
    slog = fmtatcensus(filesmis,attypes_atzahlen,atcounts,nsmis,nfailed; sorted=true)
    print.(slog)
    return nothing
end
