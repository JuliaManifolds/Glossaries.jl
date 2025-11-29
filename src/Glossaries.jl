module Glossaries

"""
    GlossaryTerm

An abstract type representing a term in a glossary.
"""
abstract type GlossaryTerm end

"""
    Glossary{T}

A glossary containing terms of type `T` where `T` is a subtype of `GlossaryTerm`.
"""
struct Glossary{T<:GlossaryTerm}
    terms::Dict{Symbol, T}
end

"""
    Term{P}

A concrete implementation of a glossary term with a dictionary of properties.
These properties can be
* `String`s
* a function `(; kwargs...) -> String`
* other further (nested)) [`GlossaryTerm`](@ref)s
"""
struct Term{P<:<:Union{GlossaryTerm,String,<:Function}} <: GlossaryTerm
    name::String
    properties::Dict{Symbol, P}
end

end # module Glossaries
