"""
    Term{P} <: GlossarEntry

A concrete implementation of a term in a [`Glossary`](@ref).

# Fields
* `properties::Dict{Symbol, P}`: A dictionary of properties associated with the term

These properties can be

* `String`s
* a function `(args...; kwargs...) -> String`
* other further (nested)) [`GlossarEntry`](@ref)s

# Constructors

    Term(properties = Dict{Symbol, Union{GlossarEntry, String, <:Function}}())

Create a new empty [`Term`](@ref) with the given `name`.

    Term(name::String)

Create a new empty [`Term`](@ref) and directly set its `:name`.
"""
struct Term{T <: Union{String, <:Function}} <: GlossarEntry
    properties::Dict{Symbol, T}
    function Term(
            properties::Dict{Symbol, T} = Dict{Symbol, Union{String, <:Function}}()
        ) where {T <: Union{String, <:Function}}
        return new{T}(properties)
    end
end
function Term(name::String)
    return Term(Dict{Symbol, Union{String, <:Function}}(:name => name))
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

function _print(io::IO, glossary::Glossary)
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
    return s
end

_doc_define_entry = """
    define!(glossary::Glossary, key::Symbol, name::String)
    define!(glossary::Glossary, key::Symbol, term::T) where {T <: GlossarEntry}
    define!(wm::Module, key::Symbol, name::String)
    define!(wm::Module, key::Symbol, term::T) where {T <: GlossarEntry}

Define a new [`Term`](@ref) in the [`Glossary`](@ref) `glossary` at `key`
or a new [`Term`](@ref)`(name)` if just providing a string.

If a `Module` `wm` is given, the term is added to the current active glossary
"""

@doc "$(_doc_define_entry)"
define!(glossary::Glossary, key::Symbol, name::String = "$(key)") = define!(glossary, key, Term(name))

@doc "$(_doc_define_entry)"
function define!(glossary::Glossary{T}, key::Symbol, entry::S) where {T, S <: T}
    glossary.terms[key] = entry
    return glossary
end
@doc "$(_doc_define_entry)"
function define!(wm::Module, key::Symbol, name::String = "")
    glossary = wm.current_glossary()
    if isnothing(glossary)
        glossary = Glossary()
        define!(wm, glossary)
    end
    define!(glossary, key, name)
    return glossary
end
@doc "$(_doc_define_entry)"
function define!(wm::Module, key::Symbol, term::S) where {S <: GlossarEntry}
    glossary = wm.current_glossary()
    # if we do not have a glossary yet, or the term is the glossary itself:
    # (here in the implicit case, avoid recursion, this has to be done explicitly)
    if isnothing(glossary) || (term === glossary)
        glossary = Glossary()
        define!(wm, glossary)
    end
    define!(glossary, key, term)
    return glossary
end

_doc_define_gloss = """
    define!(wm::Module, glossary::Glossary)

Set the current active glossary in the given module `wm` to `glossary`.
Soo also [`current_glossary!`](@ref).
"""

@doc "$(_doc_define_gloss)"
define!(wm::Module, glossary::Glossary) = wm.current_glossary!(glossary)

_doc_define_prop = """
    define!(wm::Module, entry::Symbol, property::Symbol, args...)
    define!(glossary::Glossary, entry::Symbol, property::Symbol, args...)

Define a property `property` with value `args...` for the [`Term`](@ref) at the `key` in [`Glossary`](@ref) `glossary`.
If the term does not exist yet, it is created as an empty [`Term`](@ref)`()`.

If a `Module` `wm` is given, the term is added to the current active glossary of that module.
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
    return glossary
end
@doc "$(_doc_define_prop)"
function define!(wm::Module, entry::Symbol, property::Symbol, args...)
    glossary = wm.current_glossary()
    if isnothing(glossary)
        glossary = Glossary()
        define!(wm, glossary)
    end
    define!(glossary, entry, property, args...)
    return glossary
end

"""
    @define!(entry::Symbol, name::String)
    @define!(entry::Symbol, term::T) where {T <: GlossarEntry}
    @define!(entry::Symbol, property::Symbol, args...)

A macro to define a new [`Term`](@ref) in the [`current_glossary`](@ref) of the current module
or a property of a [`Term`](@ref).
If given a String `name` is provided, a new [`Term`](@ref)`(name)` is created and added to the
current glossary.

Since this requires to call `@__MODULE__`, this is wrapped in a macro for convenience.
"""
macro define!(args...)
    return esc(:(Glossaries.define!(@__MODULE__, $(args...))))
end

# Access to terms and Glossaries with getindex

"""
    getindex(glossary::Glossary, key::Symbol)
    glossary[key::Symbol]

Access the entry at `key` in the given [`Glossary`](@ref) `glossary`.
"""
function Base.getindex(glossary::Glossary, key::Symbol)
    if haskey(glossary.terms, key)
        return glossary.terms[key]
    else
        error("Key $(key) not found in glossary.")
    end
end

function Base.setindex!(glossary::Glossary{T}, value::S, key::Symbol) where {T, S <: T}
    glossary.terms[key] = value
    return glossary
end

"""
    getindex(term::Term, key::Symbol)
    term[key::Symbol]

Access the property `key` in the given [`Term`](@ref) `term`.
"""
function Base.getindex(term::Term, key::Symbol)
    if haskey(term.properties, key)
        return term.properties[key]
    else
        error("Key $(key) not found in term.")
    end
end

function Base.setindex!(term::Term{P}, value::Q, key::Symbol) where {P, Q <: P}
    term.properties[key] = value
    return term
end
