"""
    TermFormat

A format for glossary terms.
"""
abstract type TermFormat end

function (tf::TermFormat)(glossary::Glossary, keys = keys(glossary.terms); kwargs...)
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

function (tf::TermFormat)(glossary::Glossary, key::Symbol; kwargs...)
    s = ""
    if haskey(glossary.terms, key)
        s *= tf(glossary.terms[key]; kwargs...)
    else
        @warn "Key $(key) not found in glossary. Ignoring it."
    end
    return s
end


"""
    Argument <: TermFormat

A format representing a function argument.
"""
struct Argument <: TermFormat
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
    Keyword <: TermFormat

A format representing a function keyword argument.
"""
struct Keyword <: TermFormat
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
    Math <: TermFormat

print the math format
"""
struct Math <: TermFormat end

# Functor for a term
function (::Math)(term::Term; kwargs...)
    return _print(term, :math; kwargs...)
end

"""
    MathTerm <: TermFormat

print the math as a term in text, using the description if it exists, otherwise just the name
as prefix

# Fields
* `delimiter::String`: the delimiter to use around the math expression

# Constructor
    MathTerm(delimiter::String="``")

Use the default Julia documentation math delimiter ``` ``...`` ```.
"""
struct MathTerm <: TermFormat
    delimiter::String
end
MathTerm() = MathTerm("``")

# Functor for a term
function (mt::MathTerm)(term::Term; kwargs...)
    return "$(get(term.properties, :description, term.name)) $(mt.delimiter)$(_print(term, :math; kwargs...))$(mt.delimiter)"
end

"""
    Plain <: TermFormat

A plain format representing just the term name.
"""
struct Plain <: TermFormat end

# Functor for a term
function (::Plain)(term::Term; kwargs...)
    return term.name
end
