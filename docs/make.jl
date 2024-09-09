using PhyloPickMe
using Documenter

DocMeta.setdocmeta!(PhyloPickMe, :DocTestSetup, :(using PhyloPickMe); recursive=true)

makedocs(;
    modules=[PhyloPickMe],
    authors="Joseph Rusinko",
    sitename="PhyloPickMe.jl",
    format=Documenter.HTML(;
        canonical="https://jrusinko.github.io/PhyloPickMe.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jrusinko/PhyloPickMe.jl",
    devbranch="master",
)
