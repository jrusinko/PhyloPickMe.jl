

function powers_matrix(t::Vector{Float64}, r::Int)
    return hcat([t .^ j for j in 0:r]...)
end


function convertDF(d, mytaxaDict)
    @inbounds for i in 1:nrow(d)
        @inbounds for j in 6:8
            d[i, j] *= d[i, 9]
        end
    end
    d[!, :6] = round.(Int, d[!, :6])
    d[!, :7] = round.(Int, d[!, :7])
    d[!, :8] = round.(Int, d[!, :8])
    d[!, :9] = round.(Int, d[!, :9])
    d[!, :2] = map(x -> get(mytaxaDict, x, -1), d[!, :2])
    d[!, :3] = map(x -> get(mytaxaDict, x, -1), d[!, :3])
    d[!, :4] = map(x -> get(mytaxaDict, x, -1), d[!, :4])
    d[!, :5] = map(x -> get(mytaxaDict, x, -1), d[!, :5])
    return d
end

function numer(k::Integer, n::Integer)
    ans = dot(pk[202:600, k+1], pnk[202:600, n-k+1])
    ans = ans + 0.5 * pk[201, k+1] * pnk[201, n-k+1] + 0.5 * pk[601, k+1] * pnk[601, n-k+1]
    return ans
end

function denomi(k::Integer, n::Integer)
    ans = dot(pk[2:200, k+1], pnk[2:200, n-k+1])
    ans = ans + 0.5 * pk[1, k+1] * pnk[1, n-k+1] + 0.5 * pk[201, k+1] * pnk[201, n-k+1]
    return ans
end

function weight(k::Int, n::Int)
    num = numer(k, n)
    denom = denomi(k, n)
    value = 2 * abs(num / (denom + num) - 0.5)
    return value
end

function computeScoreTable(scorevec::DataFrame)
    keys = Tuple{Int64,Int64}.(eachrow(scorevec))
    values::Vector{Float64} = weight.(scorevec[:, 1], scorevec[:, 2])
    return Dict(keys .=> values)
end

function makeTaxaDict(setoftaxa)
    taxaDict = Dict(setoftaxa[1] => 1::Integer)
    @inbounds for j in 2:length(setoftaxa)
        taxaDict[setoftaxa[j]] = j::Integer
    end
    return taxaDict
end

function makeRelScores(d)
    test1 = select(d, [:CF12_34, :ngenes])
    test1a = unique(test1)
    rename!(test1a, :CF12_34 => :k)
    test2 = select(d, [:CF13_24, :ngenes])
    test2a = unique(test2)
    rename!(test2a, :CF13_24 => :k)
    test3 = select(d, [:CF14_23, :ngenes])
    test3a = unique(test3)
    rename!(test3a, :CF14_23 => :k)
    return unique([test1a; test2a; test3a])
end


function updateScores!(d, scoretable)
    scores = zeros(Float64, size(d)[1])  # Preallocate scores array

    @inbounds @simd for i in 1:nrow(d)
        scores[i] = (scoretable[d[i, 6], d[i, 9]] + scoretable[d[i, 7], d[i, 9]] + scoretable[d[i, 8], d[i, 9]]) / 3
    end

    d[!, :score] .= scores  # Assign scores directly to the :score column
    return d
end


function ColMeans(A)
    scores = sum(A, dims=1)
    @simd for i in 1:size(A)[2]
        scores[i] = scores[i] / nnz(A[:, i])
    end
    return (scores)
end

function makeScoreArray(d)
    Is::Vector{Int64} = [1:nrow(d); 1:nrow(d); 1:nrow(d); 1:nrow(d)]
    Js::Vector{Int64} = [d[:, 2]; d[:, 3]; d[:, 4]; d[:, 5]]
    Vs::Vector{Float64} = [d[:, 10]; d[:, 10]; d[:, 10]; d[:, 10]]

    return sparse(Is, Js, Vs)
end


function removerow(array, loc)
    removerows = array[:, loc].nzind
    includerows = setdiff(1:size(array)[1], removerows)
    return array[includerows, 1:end.!=loc]
end

function classification(n)
    classification = "error"
    if n > .9802
        classification = "exceptional"
    elseif n > .9355
        classification = "very good"
    elseif n > .8182
        classification = "good"
    elseif n > .5
        classification = "bad"
    elseif n >- 0
        classification = "very bad"
    end
    return(classification)
end

function MakeClassVector(out)
    class = []
    for i = 1:size(out,1)
        push!(class,classification(out[i,2]))
    end
    return class
end





function runLoop(tax, taxscores, sarray)
    out = []
    while length(tax) > 5
        #spot = length(tax)
        minval = minimum(taxscores)
        minloc = argmin(taxscores)[2]
        classval =  classification(minval) 
        push!(out, [tax[minloc]::String, minval::Float64])
        sarray = removerow(sarray, minloc)
        taxscores = ColMeans(sarray)
        tax = tax[1:end.!=minloc]

    end
    for i in 1:5
        push!(out, [tax[i], taxscores[i]])
    end
    return out
end

function count_taxa_occurrences(gene_trees::Vector{HybridNetwork}, taxa_labels::Vector{String})
    taxa_counts = Dict{String,Integer}()

    for tree in gene_trees
        tip_labels = tipLabels(tree)

        for taxa_label in taxa_labels
            if taxa_label in tip_labels
                taxa_counts[taxa_label] = get(taxa_counts, taxa_label, 0) + 1
            end
        end
    end

    return taxa_counts
end

function get_counts_for_taxa(taxa_counts::Dict{String,Integer}, T::Vector{String})
    counts = [get(taxa_counts, taxa, 0) for taxa in T]
    return counts
end

function format_output(a)
    temp = hcat(a...)
    out = permutedims(temp)
    out[:, 1] = map(x -> string(x), out[:, 1])
    return out
end

function add_occupancy(out, countdict)
    out = map(x -> string(x), out)
    tcounts = get_counts_for_taxa(countdict, out)
    return tcounts
end

