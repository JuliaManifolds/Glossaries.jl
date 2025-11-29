"""
    TermFormatter

A format for glossary terms. It always acts as a functor with the following mathods:

    (tf::TermFormatter)(keys::Vector{Symbol}; kwargs...)`
    (tf::TermFormatter)(glossary::Glossary, keys::Vector{Symbol}; kwargs...)`

format all given `keys` of a `glossary` using the format `tf`.
If the `glossary` is not given, the [`current_glossary`](@ref) is used,
if no `keys` are given, all keys of the glossary are used.

    (tf::TermFormatter)(key::Symbol; kwargs...)`
    (tf::TermFormatter)(glossary::Glossary, key::Symbol; kwargs...)`

format the given `key` of a `glossary` using the format `tf`.
If the `glossary` is not given, the [`current_glossary`](@ref) is used.

Formatting a single [`Term`](@ref) is done by calling

    (tf::TermFormatter)(term::Term; kwargs...)

where `term` is the [`Term`](@ref) to format. This should be implemented by all subtypes of `TermFormatter`.
"""
abstract type TermFormatter end

function (tf::TermFormatter)(glossary::Glossary, keys = keys(glossary.terms); kwargs...)
    s = ""
    first = true
    for k in keys
        !first && (s *= "\n")
        first && ((first = false))
        if !haskey(glossary.terms, k)
            @warn "Key $(k) not found in glossary. Ignoring it."
            continue
        end
        s *= tf(glossary.terms[k]; kwargs...)
    end
    return s
end
function (tf::TermFormatter)(
        ks::Vector{Symbol} = !isnothing(current_glossary()) ? collect(keys(current_glossary().terms)) : Symbol[]; kwargs...
    )
    glossary = current_glossary()
    isnothing(glossary) && error("No current glossary found. Please create a glossary  first.")
    return tf(glossary, ks; kwargs...)
end

function (tf::TermFormatter)(glossary::Glossary, key::Symbol; kwargs...)
    s = ""
    if haskey(glossary.terms, key)
        s *= tf(glossary.terms[key]; kwargs...)
    else
        @warn "Key $(key) not found in glossary. Ignoring it."
    end
    return s
end
function (tf::TermFormatter)(key::Symbol; kwargs...)
    glossary = current_glossary()
    isnothing(glossary) && error("No current glossary found. Please create a glossary  first.")
    return tf(glossary, key; kwargs...)
end


"""
    Argument <: TermFormatter

A format representing a function argument.
"""
struct Argument <: TermFormatter
    show_type::Bool
end
Argument(; show_type::Bool = true) = Argument(show_type)

# Functor for a term
function (arg::Argument)(term::Term; kwargs...)
    s = "* `$(term.name)"
    if haskey(term.properties, :type) && arg.show_type
        s *= "::`[`$(_print(term, :type; kwargs...))`](@ref)"
    else
        s *= "`"
    end
    s *= ": $(_print(term, :description; kwargs...))"
    return s
end

"""
    Keyword <: TermFormatter

A format representing a function keyword argument.
"""
struct Keyword <: TermFormatter
    show_type::Bool
end
Keyword(; show_type::Bool = true) = Keyword(show_type)

# Functor for a term
function (kw::Keyword)(term::Term; kwargs...)
    s = "* `$(term.name)"
    if haskey(term.properties, :type) && kw.show_type
        s *= "::`[`$(_print(term, :type; kwargs...))`](@ref)"
    else
        s *= "`"
    end
    df = get(term.properties, :default, "")
    length(df) > 0 && (s *= "` = $(df)`")
    s *= ": $(_print(term, :description; kwargs...))"
    return s
end

"""
    Math <: TermFormatter

print the math format
"""
struct Math <: TermFormatter end

# Functor for a term
function (::Math)(term::Term; kwargs...)
    return _print(term, :math; kwargs...)
end

"""
    MathTerm <: TermFormatter

print the math as a term in text, using the description if it exists, otherwise just the name
as prefix

# Fields
* `delimiter::String`: the delimiter to use around the math expression

# Constructor
    MathTerm(delimiter::String="``")

Use the default Julia documentation math delimiter ``` ``...`` ```.
"""
struct MathTerm <: TermFormatter
    delimiter::String
end
MathTerm() = MathTerm("``")

# Functor for a term
function (mt::MathTerm)(term::Term; kwargs...)
    return "$(get(term.properties, :description, term.name)) $(mt.delimiter)$(_print(term, :math; kwargs...))$(mt.delimiter)"
end

"""
    Plain <: TermFormatter

A plain format representing just the term name.
"""
struct Plain <: TermFormatter end

# Functor for a term
function (::Plain)(term::Term; kwargs...)
    return term.name
end
