"""
    GlossarEntry

An abstract type representing a term in a glossary.
"""
abstract type GlossarEntry end

"""
    Glossary{T} <: GlossarEntry

# Fields
* `terms::Dict{Symbol, T}` : A dictionary mapping term names (as symbols) to terms of type `T`.

A glossary containing entries of type `T` where `T` is a subtype of [`GlossarEntry`](@ref).
As [`Glossary`](@ref) is a subtype of [`GlossarEntry`](@ref), glossaries can be nested within other glossaries.

# Constructor

    Glossary(terms = Dict{Symbol, GlossarEntry}(); current = true

Creates a new (empty) `Glossary` instance.
"""
struct Glossary{T <: GlossarEntry} <: GlossarEntry
    terms::Dict{Symbol, T}
end
Glossary() = Glossary(Dict{Symbol, GlossarEntry}())
