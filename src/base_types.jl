"""
    GlossarEntry

An abstract type representing a term in a glossary.
"""
abstract type GlossarEntry end

function current_glossary! end

"""
    Glossary{T} <: GlossarEntry

# Fields
* `terms::Dict{Symbol, T}` : A dictionary mapping term names (as symbols) to terms of type `T`.

A glossary containing entries of type `T` where `T` is a subtype of `GlossarEntry`.
Since `Glossary` is a subtype of `GlossarEntry`, glossaries can be nested within other glossaries.

# Constructor
    Glossary()
    Glossary(terms::Dict{Symbol, T}) where {T <: GlossarEntry}

Creates a new (empty) `Glossary` instance. Both constructors set the created glossary as the [`current_glossary`](@ref).
"""
struct Glossary{T <: GlossarEntry} <: GlossarEntry
    terms::Dict{Symbol, T}
    function Glossary(terms::Dict{Symbol, T}) where {T <: GlossarEntry}
        glossary = new{T}(terms)
        current_glossary!(glossary)
        return glossary
    end
end
