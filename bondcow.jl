# bondcow is a bond-counter. As in, it scans a list of smiles and tells you how many bonds of each type it has

# here0 merge the bonddescription machinery. I think I have another prog that checks this. I think it's amif?
# here0 make a fun in case a prog wants this info! Return the vecs rather than write to disk
# here1 Eventually change the default behavior so scanning a file via bondcow.jl writes to disk at the end rather than print to screen (or maybe do both unless the user requests no printing). That way the user can get disconnected and still get their answer at the end

include("machinery-bondcow.jl")

if (length(ARGS) == 0)
    printhelp_bondcow()
end

behaviorbondcow = loadbehavior_bondcow(ARGS)

if behaviorbondcow.modehelp
    printhelp_bondcow()
elseif behaviorbondcow.modeversion
    printversion_bondcow()
elseif behaviorbondcow.modecompareversion
    compareversion_bondcow()
elseif behaviorbondcow.moderequirements
    installrequirements_bondcow()
elseif behaviorbondcow.modeselfupdate
    selfupdate_bondcow()
end

if behaviorbondcow.modeatoms
    # here1 fix the makeatcensus call. modehybridization should be read from the struct; maybe make an alias that takes the filename and hybridization and packs these into a BehaviorBondcow?
    (attypes,atcounts,nsmis,nfailed) = makeatcensus(behaviorbondcow.filesmis;modehybridization=false)
    printatcensus(behaviorbondcow.filesmis,attypes,atcounts,nsmis,nfailed)
elseif behaviorbondcow.modebonds
    (bondtypes,bondcounts,nsmis,nfailed,anomalybonds) = makebondcensus(behaviorbondcow.filesmis)
    printbondcensus(behaviorbondcow.filesmis,bondtypes,bondcounts,nsmis,nfailed,anomalybonds)
elseif behaviorbondcow.modehybridization
    (attypes,atcounts,nsmis,nfailed) = makeatcensus(behaviorbondcow.filesmis;modehybridization=true)
    printatcensus(behaviorbondcow.filesmis,attypes,atcounts,nsmis,nfailed)
end

