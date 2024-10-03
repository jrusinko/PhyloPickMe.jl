using PhyloPickMe
using Documenter
using DocMeta

DocMeta.setdocmeta!(PhyloPickMe, :DocTestSetup, :(using PhyloPickMe); recursive=true)

makedocs(;
    modules=[PhyloPickMe],
    authors="Joseph Rusinko",
    sitename="PhyloPickMe.jl",
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jrusinko/PhyloPickMe.jl.git",
    branch="gh-pages",
    target="build"
)
