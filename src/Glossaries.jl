"""
    Glossaries.jl


"""
module Glossaries

"""
    GlossaryTerm

An abstract type representing a term in a glossary.
"""
abstract type GlossaryTerm end

"""
    Term{P}

A concrete implementation of a glossary term with a dictionary of properties.
These properties can be
* `String`s
* a function `(; kwargs...) -> String`
* other further (nested)) [`GlossaryTerm`](@ref)s
"""
struct Term{P <: Union{GlossaryTerm, String, <:Function}} <: GlossaryTerm
    name::String
    properties::Dict{Symbol, P}
end
Term(name::String) = Term(name, Dict{Symbol, Union{GlossaryTerm, String, <:Function}}())

function Base.show(io::IO, term::Term)
    s = "“$(term.name)” (term)"
    (length(term.properties)) == 0 && return print(io, s)
    for (k, v) in term.properties
        if v isa String
            s *= "\n  - :$(k)\t“$(v)”"
        elseif v isa Function
            s *= "\n  - :$(k)\t$(v())"
        else # GlossaryTerm
            t = replace("$(repr(v))", "\n" => "\n\t")
            s *= "\n  - :$(k)\t$(t)"
        end
    end
    return print(io, s)
end

"""
    define!(term::Term{P}, name::Symbol, value::Q) where {P, Q<:P}

Define a property `name` with value `value` for the given [`Term`](@ref) `term`.
"""
function define!(term::Term{P}, name::Symbol, value::Q) where {P, Q <: P}
    term.properties[name] = value
    return term
end


"""
    Glossary{T}

A glossary containing terms of type `T` where `T` is a subtype of `GlossaryTerm`.
"""
struct Glossary{T <: GlossaryTerm}
    terms::Dict{Symbol, T}
end
Glossary() = Glossary{GlossaryTerm}(Dict{Symbol, GlossaryTerm}())

function Base.show(io::IO, glossary::Glossary)
    length(glossary.terms) == 0 && return print(io, "An Empty Glossary")
    s = "Glossary with $(length(glossary.terms)) terms:"
    for (k, v) in glossary.terms
        s *= "\n* :$(k)\t$(repr(v))"
    end
    return print(io, s)
end

"""
    define!(glossary::Glossary, entry::Symbol, name)

Define a new [`Term`](@ref) with the given `name` and add it to the [`Glossary`](@ref) `glossary` at `entry`.
"""
define!(glossary::Glossary, entry::Symbol, name::String) = define!(glossary, entry, Term(name))

function define!(glossary::Glossary{T}, entry::Symbol, term::S) where {T, S <: T}
    glossary.terms[entry] = term
    return glossary
end

"""
    define!(glossary::Glossary, entry::Symbol, property::Symbol, args...)

Define a property `property` with value `args...` for the [`Term`](@ref) at `entry` in the given [`Glossary`](@ref) `glossary`.
"""
function define!(glossary::Glossary, entry::Symbol, property::Symbol, args...)
    define!(glossary.terms[entry], property, args...)
    return glossary
end

end # module Glossaries
