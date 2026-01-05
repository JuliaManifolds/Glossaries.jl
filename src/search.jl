#
#
# Search functionality

"""
    search_in(glossary::Glossary{T}, query) where {T}

Search for a `query` string in all terms/entries of a Glossary.
Internally, this function calls `occursin`, so the `query` can be any `needle` that function accepts.

This returns an array of `Pairs` where the first element is the `Symbol` or vector of Symbols
where to find the corresponding term, and the second element is the term itself.
"""
function search_in(glossary::Glossary{T}, query) where {T}
    results = Pair{Union{Nothing, Symbol, Vector{Symbol}}, T}[]

    for (key, entry) in glossary.terms
        local_results = search_in(entry, query)
        for result in local_results
            if isnothing(result.first) # we have a direct hit in a term of this glossary
                push!(results, Pair(key, result.second))
            elseif isa(result.first, Symbol) # we have a hit in a sub-glossary term
                push!(results, Pair([key, result.first], result.second))
            else # we already have a vector, append key
                push!(results, Pair([key, result.first...], result.second))
            end
        end
    end
    return results
end

"""
    search_in(entry::Term, query::AbstractString)

A small internal function to search in a term. To match the glossary search interface,
this method returns a vector of length one containing the pair `(nothing, term)` if there is a match,
otherwise an empty vector.
"""
function search_in(entry::Term, query)
    if occursin(query, repr(entry))
        return [Pair(nothing, entry)]
    else
        return Pair{Union{Nothing, Symbol}, Term}[]
    end
end

"""
    (glossary::Glossary)(query)

Given a [`Glossary`](@ref) instance, this allows to search for a `query` string in all its terms/entries
by calling `glossary(query)`.

```
Glossaries.Glossary(Dict{Symbol,Glossaries.GlossarEntry}([
    :title => Glossaries.Term("A simple Glossary Test"),
    :names => Glossaries.Glossary(Dict{Symbol,Glossaries.Term}([
        :Anton => Glossaries.Term("Anton Test"),
        :Egon => Glossaries.Term("Egon Est"),
        ])),
    ]))
```
"""
function (glossary::Glossary)(query)
    return search_in(glossary, query)
end
