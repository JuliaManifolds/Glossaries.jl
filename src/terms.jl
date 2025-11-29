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
Term(name::String = "") = Term(name, Dict{Symbol, Union{GlossaryTerm, String, <:Function}}())

function Base.show(io::IO, term::Term)
    return _print(io, term)
end

function _print(io::IO, term::Term, args...; kwargs...)
    s = (length(term.name) == 0) ? "(unnamed term)" : "“$(term.name)” (term)"
    (length(term.properties)) == 0 && return print(io, s)
    for k in keys(term.properties)
        s *= "\n  - :$(k)\t$(_print(term, k, args...; kwargs...))"
    end
    return print(io, s)
end

function _print(term::Term, key::Symbol, args...; default = "", kwargs...)
    !haskey(term.properties, key) && return default
    return __print(term.properties[key], args...; kwargs...)
end

__print(v::String, args...; kwargs...) = v
function __print(v::Function, args...; kwargs...)
    # estimate from first function method
    m = methods(v)[1]
    (m.nargs != (length(args) + 1)) && return "$(v)"
    return v(args...; kwargs...)
end
__print(v::GlossaryTerm, args...; kwargs...) = _print(v, args...; kwargs...)

"""
    add!(term::Term{P}, name::Symbol, value::Q) where {P, Q<:P}

Add a property `name` with value `value` for the given [`Term`](@ref) `term`.
"""
function add!(term::Term{P}, name::Symbol, value::Q) where {P, Q <: P}
    term.properties[name] = value
    return term
end

function Glossary()
    glossary = Glossary(Dict{Symbol, GlossaryTerm}())
    current_glossary!(glossary)
    return glossary
end

function Base.show(io::IO, glossary::Glossary)
    length(glossary.terms) == 0 && return print(io, "An Empty Glossary")
    s = "Glossary with $(length(glossary.terms)) terms:"
    for (k, v) in glossary.terms
        s *= "\n* :$(k)\t$(repr(v))"
    end
    return print(io, s)
end

_doc_define_entry = """
    define!(entry::Symbol, name::String)
    define!(entry::Symbol, term::T) where {T <: GlossaryTerm}
    define!(glossary::Glossary, entry::Symbol, name::String)
    define!(glossary::Glossary, entry::Symbol, term::T) where {T <: GlossaryTerm}

Define a new [`Term`](@ref) in the [`Glossary`](@ref) `glossary` at `entry`.
If given a `name`, a new [`Term`](@ref)`(name)` is created and added.

If no `glossary` is given, the current active glossary (or the last created glossary) is used. If none was created yet, a new empty glossary is created.
"""

@doc "$(_doc_define_entry)"
define!(glossary::Glossary, entry::Symbol, name::String = "") = define!(glossary, entry, Term(name))

@doc "$(_doc_define_entry)"
function define!(entry::Symbol, name::String = "")
    glossary = current_glossary()
    if isnothing(glossary)
        glossary = Glossary()
    end
    define!(glossary, entry, name)
    current_glossary!(glossary)
    return glossary
end

@doc "$(_doc_define_entry)"
function define!(glossary::Glossary{T}, entry::Symbol, term::S) where {T, S <: T}
    glossary.terms[entry] = term
    current_glossary!(glossary)
    return glossary
end

@doc "$(_doc_define_entry)"
function define!(entry::Symbol, term::S) where {S <: GlossaryTerm}
    glossary = current_glossary()
    if isnothing(glossary)
        glossary = Glossary()
    end
    define!(glossary, entry, term)
    current_glossary!(glossary)
    return glossary
end

_doc_define_prop = """
    define!(entry::Symbol, property::Symbol, args...)
    define!(glossary::Glossary, entry::Symbol, property::Symbol, args...)

Define a property `property` with value `args...` for the [`Term`](@ref) at `entry` in [`Glossary`](@ref) `glossary`.
If the term does not exist yet, it is created as an empty [`Term`](@ref)`()`.
If no `glossary` is given, the current active glossary (or the last created glossary) is used. If none was created yet, a new empty glossary is created.
"""

@doc "$(_doc_define_prop)"
function define!(glossary::Glossary, entry::Symbol, property::Symbol, args...)
    if !haskey(glossary.terms, entry)
        define!(glossary, entry, Term())
    end
    add!(glossary.terms[entry], property, args...)
    return glossary
end

@doc "$(_doc_define_prop)"
function define!(entry::Symbol, property::Symbol, args...)
    glossary = current_glossary()
    if isnothing(glossary)
        glossary = Glossary{T}()
    end
    define!(glossary, entry, property, args...)
    current_glossary!(glossary)
    return glossary
end
