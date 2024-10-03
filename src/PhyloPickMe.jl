module PhyloPickMe
using Statistics
using FLoops
using PhyloNetworks
#using PhyloPlots
using DataFrames
using DelimitedFiles
using SparseArrays
using CSV
using LinearAlgebra
using FastPow
using Dates
using Pkg

## INclude InternalFunctions

include("InternalFunctions.jl")


export PickMe
"""
    PickMe(InputTreeFile::String, OutputFile::String)

Classify all samples which occur in the InputTreeFile using PickMe.
"""
function PickMe(InputTreeFile::String, OutputFile::String)
    genetrees = readMultiTopology(InputTreeFile)
    prange = range(0.0, 1.0, 601)
    prange = collect(prange)
    pk = powers_matrix(prange, size(genetrees)[1])
    pnk = pk[reverse(1:601), :]
    taxa::Vector{String} = tipLabels(genetrees)
    taxacounts = count_taxa_occurrences(genetrees, taxa)
    taxaDict = makeTaxaDict(taxa)
    q, t::Vector{String} = countquartetsintrees(genetrees)
    df = writeTableCF(q, t)
    df = convertDF(df, taxaDict)
    Scores = makeRelScores(df)
    Qscore = computeScoreTable(pk,pnk,Scores)
    df = updateScores!(df, Qscore)
    ScoreArray = makeScoreArray(df)
    Tscores = ColMeans(ScoreArray)

    output = runLoop(taxa, Tscores, ScoreArray)
    output = format_output(output)
    tcounts = add_occupancy(output[:, 1], taxacounts)
    coverage = tcounts / size(genetrees)[1]
    classes = MakeClassVector(output)
    output = [output classes coverage]
    ctime = now()
    currenttime = Dates.format(ctime, "mm-dd-yyyy HH:MM:SS")
    numgenetrees = string(size(genetrees)[1])
    numsamples = string(size(taxa)[1])
    project_info = Pkg.project()
    versionNumber = string(project_info.version)


    open(OutputFile; write=true) do f
        write(f, "#PickMe version ", versionNumber, " was run on ", currenttime, " using the input file ", InputTreeFile, " which contained ", numgenetrees, " gene trees, and ", numsamples, " samples. \n",)
        write(f, "Sample, PickMeScore, PickMe Classification ,Occupancy \n")
        writedlm(f, output, ",")
    end
    return output
end
end # module PickMe