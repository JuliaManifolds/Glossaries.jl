"""
    GlossaryTerm

An abstract type representing a term in a glossary.
"""
abstract type GlossaryTerm end

function current_glossary! end

"""
    Glossary{T}

# Fields
* `terms::Dict{Symbol, T}` : A dictionary mapping term names (as symbols) to terms of type `T`.

A glossary containing terms of type `T` where `T` is a subtype of `GlossaryTerm`.

# Constructor
    Glossary()
    Glossary(terms::Dict{Symbol, T}) where {T <: GlossaryTerm}

Creates a new (empty) `Glossary` instance. Both constructors set the created glossary as the [`current_glossary`](@ref).
"""
struct Glossary{T <: GlossaryTerm}
    terms::Dict{Symbol, T}
    function Glossary(terms::Dict{Symbol, T}) where {T <: GlossaryTerm}
        glossary = new{T}(terms)
        current_glossary!(glossary)
        return glossary
    end
end
