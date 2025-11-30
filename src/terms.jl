"""
    Term{P} <: GlossarEntry

A concrete implementation of a term in a [`Glossary`](@ref).

# Fields
* `name::String`: The name of the term.
* `properties::Dict{Symbol, P}`: A dictionary of properties associated with the term

These properties can be

* `String`s
* a function `(args...; kwargs...) -> String`
* other further (nested)) [`GlossarEntry`](@ref)s

# Constructors

    Term(terms = Dict{Symbol, Union{GlossarEntry, String, <:Function}}())

Create a new empty [`Term`](@ref) with the given `name`.

    Term(name::String)

Create a new empty [`Term`](@ref) and directly set its `:name`.
"""
struct Term{T <: Union{GlossarEntry, String, <:Function}} <: GlossarEntry
    properties::Dict{Symbol, T}
    function Term(
        terms::Dict{Symbol, T} = Dict{Symbol, Union{GlossarEntry, String, <:Function}}()
        ) where {T <: Union{GlossarEntry, String, <:Function}}
        return new{T}(terms)
    end
end
function Term(name::String)
    Term( Dict{Symbol, Union{GlossarEntry, String, <:Function}}(:name => name))
end

function Base.show(io::IO, term::Term)
    return _print(io, term)
end

function _print(io::IO, term::Term, args...; kwargs...)
    return print(io, _print(term, args...; kwargs...))
end

function _print(term::Term, args...; kwargs...)
    # We use :name as a special field
    n = "“$(get(term.properties, :name, ""))”"
    s = "Term $n"
    (length(term.properties)) == 0 && return s * " with no properties."
    for k in keys(term.properties)
        v = replace(_print(term.properties[k], args...; kwargs...), '\n' => "\n\t")
        s *= "\n  - :$(k)\t$(v)"
    end
    return s
end

function _print(term::Term, key::Symbol, args...; default = "", kwargs...)
    !haskey(term.properties, key) && return default
    return _print(term.properties[key], args...; kwargs...)
end

_print(v::String, args...; kwargs...) = v
function _print(v::Function, args...; kwargs...)
    # estimate from first function method
    m = methods(v)[1]
    (m.nargs != (length(args) + 1)) && return "$(v)"
    return v(args...; kwargs...)
end

"""
    add!(term::Term{P}, name::Symbol, value::Q) where {P, Q<:P}

Add a property `name` with value `value` for the given [`Term`](@ref) `term`.
"""
function add!(term::Term{P}, name::Symbol, value::Q) where {P, Q <: P}
    term.properties[name] = value
    return term
end

function Base.show(io::IO, glossary::Glossary)
    return _print(io, glossary)
end

function _print(io, glossary::Glossary)
    length(glossary.terms) == 0 && return print(io, "An Empty Glossary")
    s = "Glossary with $(length(glossary.terms)) terms:"
    for (k, v) in glossary.terms
        if v === glossary # recursion!
            s *= "\n* :$(k)\t(Glossary - recursive reference)"
        else
            v = replace(repr(v), '\n' => "\n\t")
            s *= "\n* :$(k)\t$(v)"
        end
    end
    return print(io, s)
end

function _print(glossary::Glossary, args...; kwargs...)
    length(glossary.terms) == 0 && return "An Empty Glossary"
    s = "Glossary with $(length(glossary.terms)) terms:"
    for (k, v) in glossary.terms
        w = replace(_print(v, args...; kwargs...), '\n' => "\n\t")
        s *= "\n* :$(k)\t$(w)"
    end
    return print(io, s)
end

_doc_define_entry = """
    define!(entry::Symbol, name::String)
    define!(entry::Symbol, term::T) where {T <: GlossarEntry}
    define!(glossary::Glossary, entry::Symbol, name::String)
    define!(glossary::Glossary, entry::Symbol, term::T) where {T <: GlossarEntry}

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
function define!(glossary::Glossary{T}, key::Symbol, entry::S) where {T, S <: T}
    glossary.terms[key] = entry
    current_glossary!(glossary)
    return glossary
end

@doc "$(_doc_define_entry)"
function define!(entry::Symbol, term::S) where {S <: GlossarEntry}
    glossary = current_glossary()
    # if we do not have a glossary yet, or the term is the glossary itself:
    # (here in the implicit case, avoid recursion, this has to be done explicitly)
    if isnothing(glossary) || (term === glossary)
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
    pass_to = glossary.terms[entry]
    if pass_to isa Glossary
        define!(pass_to, property, args...)
    else
        add!(glossary.terms[entry], property, args...)
    end
    current_glossary!(glossary)
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
