"""
    TermFormatter

A format for glossary terms. It always acts as a functor with the following methods:

    (tf::TermFormatter)(keys::Vector{Symbol}; kwargs...)`
    (tf::TermFormatter)(glossary::Glossary, keys::Vector{Symbol}; kwargs...)`

format all given `keys` of a `glossary` using the format `tf`.
If the `glossary` is not given, the [`current_glossary`](@ref) is used,
if no `keys` are given, all keys of the glossary are used.

    (tf::TermFormatter)(key::Symbol, args...; kwargs...)`
    (tf::TermFormatter)(glossary::Glossary, key::Symbol, args...; kwargs...)`

format the given `key` of a `glossary` using the format `tf`.
If the `glossary` is not given, the [`current_glossary`](@ref) is used.
All additional `args...` and `kwargs...` are passed to the underlying term formatting.

Formatting a single [`Term`](@ref) is done by calling

    (tf::TermFormatter)(term::Term, args...; kwargs...)

where `term` is the [`Term`](@ref) to format. This should be implemented by all subtypes of `TermFormatter`.
To what extend a certain formatter does support additional `args...` depends on the formatter.
All should accept `kwargs...`.
"""
abstract type TermFormatter{WM} end

function (tf::TermFormatter)(glossary::Glossary, keys = keys(glossary.terms), args...; kwargs...)
    s = ""
    first = true
    for k in keys
        !first && (s *= "\n")
        first && ((first = false))
        if !haskey(glossary.terms, k)
            @warn "Key $(k) not found in glossary. Ignoring it."
            continue
        end
        s *= tf(glossary.terms[k], args...; kwargs...)
    end
    return s
end
function (tf::TermFormatter{WM})(
        ks::Vector{Symbol} = !isnothing(WM.current_glossary()) ? collect(keys(WM.current_glossary().terms)) : Symbol[];
        kwargs...
    ) where {WM}
    glossary = WM.current_glossary()
    isnothing(glossary) && error("No current glossary found. Please create a glossary  first.")
    return tf(glossary, ks; kwargs...)
end

function (tf::TermFormatter)(glossary::Glossary, key::Symbol, args...; kwargs...)
    s = ""
    if haskey(glossary.terms, key)
        s *= tf(glossary.terms[key], args...; kwargs...)
    else
        @warn "Key $(key) not found in glossary. Ignoring it."
    end
    return s
end
function (tf::TermFormatter{WM})(key::Symbol, args...; kwargs...) where {WM}
    glossary = WM.current_glossary()
    isnothing(glossary) && error("No current glossary found. Please create a glossary  first.")
    return tf(glossary, key, args...; kwargs...)
end

"""
    Argument <: TermFormatter

A format representing a function argument.

Given a [`Term`](@ref), this formatter expects the following properties to be set:
* `:name`: the name of the argument
* `:type`: the type of the argument (optional)
* `:description`: the description of the argument

This formatter prints
```
- `name::[type](@ref): description`
```

This format additionally accepts two keyword arguments, that are hence are hence not passed
to the underlying term:
* `name::String=""`: if given, this name is used instead of the term's `:name` property.
* `add_properties::Vector{Symbol}=Symbol[]`: a vector of additional properties to add to the output
  after the description.

All arguments and keyword arguments other than these are passed to the underlying property formatting,

# Fields

* `show_type::Bool`: whether to show the type of the argument

# Constructor

    Argument(show_type::Bool = true)
    @Argument(show_type::Bool = true)

Create a new `Argument` formatter, where the macro variant takes the current modules glossary
as default, see the different forms to call a formatter at [`TermFormatter`](@ref).
"""
struct Argument{WM} <: TermFormatter{WM}
    show_type::Bool
end
Argument(show_type::Bool) = Argument{Main}(show_type)
Argument(; show_type::Bool = true) = Argument{Main}(show_type)
Argument{WM}(; show_type::Bool = true) where {WM} = Argument{WM}(show_type)

macro Argument(show_type = true)
    return esc(:(Glossaries.Argument{@__MODULE__}($show_type)))
end

# Functor for a term
function (arg::Argument)(term::Term, args...; name = "", add_properties::Vector{Symbol} = Symbol[], kwargs...)
    name = length(name) > 0 ? name : get(term.properties, :name, "")
    s = "- `$(name)`"
    if haskey(term.properties, :type) && arg.show_type
        s *= "::`[`$(_print(term, :type, args...; kwargs...))`](@ref)"
    else
        s *= "`"
    end
    s *= ": $(_print(term, :description, args...; kwargs...))"
    for p in add_properties
        if haskey(term.properties, p)
            s *= " $(_print(term, p, args...; kwargs...))"
        end
    end
    return s
end


"""
    Field <: TermFormatter

A format representing a struct field.

Given a [`Term`](@ref), this formatter expects the following properties to be set:
* `:name`: the name of the field
* `:type`: the type of the field (optional)
* `:description`: the description of the field

This formatter prints
```
- `name::[type](@ref): description`
```

This format additionally accepts two keyword arguments, that are hence are hence not passed
to the underlying term:
* `add_properties::Vector{Symbol}=Symbol[]`: a vector of additional properties to add to the output
  after the description.
* `name::String=""`: if given, this name is used instead of the term's `:name` property.
* `type::String=""`: if given, this type is used instead of the term's `:type` property.

All arguments and keyword arguments other than these are passed to the underlying property formatting,


# Fields

* `show_type::Bool`: whether to show the type of the argument

# Constructor

    Field(show_type::Bool = true)
    @Field(show_type::Bool = true)

Create a new `Field` formatter, where the macro variant takes the current modules glossary
as default, see the different forms to call a formatter at [`TermFormatter`](@ref).
"""
struct Field{WM} <: TermFormatter{WM}
    show_type::Bool
end
Field(show_type::Bool) = Field{Main}(show_type)
Field(; show_type::Bool = true) = Field{Main}(show_type)
Field{WM}(; show_type::Bool = true) where {WM} = Field{WM}(show_type)

macro Field(show_type = true)
    return esc(:(Glossaries.Field{@__MODULE__}($show_type)))
end

# Functor for a term
function (arg::Field)(term::Term, args...; name = "", type = "", add_properties::Vector{Symbol} = Symbol[], kwargs...)
    name = length(name) > 0 ? name : get(term.properties, :name, "")
    s = "- `$(name)`"
    if (haskey(term.properties, :type) || length(type) > 0) && arg.show_type
        s *= length(type) > 0 ? "::$(type)" : "::`[`$(_print(term, :type, args...; kwargs...))`](@ref)"
    else
        s *= "`"
    end
    s *= ": $(_print(term, :description, args...; kwargs...))"
    for p in add_properties
        if haskey(term.properties, p)
            s *= " $(_print(term, p, args...; kwargs...))"
        end
    end
    return s
end

"""
    Keyword <: TermFormatter

A format representing a function keyword argument.
Keyword arguments are passed to `:type`, and `:default`, and `:description` properties.

This formatter expects the following properties to be set:
* `:name`: the name of the keyword argument
* `:type`: the type of the keyword argument (optional)
* `:default`: the default value of the keyword argument (optional)
* `:description`: the description of the keyword argument

This formatter prints
```
- `name::[type](@ref) = default`: description`
```

This format additionally accepts two keyword arguments, that are hence are hence not passed
to the underlying term:
* `name::String=""`: if given, this name is used instead of the term's `:name` property.
* `add_properties::Vector{Symbol}=Symbol[]`: a vector of additional properties to add to the output
  after the description.
* `default::String=""`: the default value to use instead of the stored `:default` property.

All arguments and keyword arguments other than these are passed to the underlying property formatting,

# Fields
* `show_type::Bool`: whether to show the type of the keyword argument

# Constructor

    Keyword(show_type::Bool = true)
    @Keyword(show_type::Bool = true)

Create a new `Keyword` formatter, where the macro variant takes the current modules glossary
as default, see the different forms to call a formatter at [`TermFormatter`](@ref).
"""
struct Keyword{WM} <: TermFormatter{WM}
    show_type::Bool
end
Keyword(show_type::Bool) = Keyword{Main}(show_type)
Keyword(; show_type::Bool = true) = Keyword(show_type)
Keyword{WM}(; show_type::Bool = true) where {WM} = Keyword{WM}(show_type)
Keyword(m::Module; show_type::Bool = true) = Keyword{m}(show_type)

macro Keyword(show_type = true)
    return esc(:(Glossaries.Keyword{@__MODULE__}($show_type)))
end

# Functor for a term
function (kw::Keyword)(term::Term, args...; default = "", name = "", add_properties::Vector{Symbol} = Symbol[], kwargs...)
    name = length(name) > 0 ? name : get(term.properties, :name, "")
    s = "- `$(name)`"
    if haskey(term.properties, :type) && kw.show_type
        s *= "::`[`$(_print(term, :type, args...; kwargs...))`](@ref)"
    else
        s *= "`"
    end
    df = length(default) > 0 ? default : _print(term, :default, args...; kwargs...)
    length(df) > 0 && (s *= "` = $(df)`")
    s *= ": $(_print(term, :description, args...; kwargs...))"
    for p in add_properties
        if haskey(term.properties, p)
            s *= " $(_print(term, p, args...; kwargs...))"
        end
    end
    return s
end

"""
    Math <: TermFormatter

print the math format. This formatter of a term passes all arguments and keyword arguments
to the underlying term formatting for the `:math` property.

# Constructor
    Math()
    @Math()

Create a new `Math` formatter, where the macro variant takes the current modules glossary
as default, see the different forms to call a formatter at [`TermFormatter`](@ref).
"""
struct Math{WM} <: TermFormatter{WM} end
Math() = Math{Main}()
Math(m::Module) = Math{m}()

macro Math(show_type = true)
    return esc(:(Glossaries.Math{@__MODULE__}($show_type)))
end

# Functor for a term
function (::Math)(term::Term, args...; kwargs...)
    return _print(term, :math, args...; kwargs...)
end

"""
    MathTerm <: TermFormatter

A formatter for mathematical terms.

This formatter expects the following properties to be set:
* `:description`: the description of the term
* `:math`: the math expression of the term

This formatter prints

```
description delimiter math delimiter
```

# Fields

* `delimiter::String`: the delimiter to use around the math expression

# Constructor
    MathTerm(delimiter::String="``")

Use the default Julia documentation math delimiter ``` ``...`` ```.

# Constructor

    MathTerm(delimiter::String="``")
    @MathTerm(delimiter::String="``")

Create a new `MathTerm` formatter, where the macro variant takes the current modules glossary
as default, see the different forms to call a formatter at [`TermFormatter`](@ref).
"""
struct MathTerm{WM} <: TermFormatter{WM}
    delimiter::String
end
MathTerm() = MathTerm{Main}()
MathTerm{MW}() where {MW} = MathTerm{MW}("``")
MathTerm(m::Module) = MathTerm{m}()

macro MathTerm(show_type = true)
    return esc(:(Glossaries.MathTerm{@__MODULE__}($show_type)))
end


# Functor for a term
function (mt::MathTerm)(term::Term, args...; kwargs...)
    return "$(get(term.properties, :description, "")) $(mt.delimiter)$(_print(term, :math, args...; kwargs...))$(mt.delimiter)"
end

"""
    Plain <: TermFormatter

A plain format representing just the terms `:name`.

It then prints really just the name of the term.

# Constructor
    Plain()
    @Plain()

Create a new `Plain` formatter, where the macro variant takes the current modules glossary
as default, see the different forms to call a formatter at [`TermFormatter`](@ref).
"""
struct Plain{WM} <: TermFormatter{WM}
    field::Symbol
end
Plain(s::Symbol = :name) = Plain{Main}(s)
Plain(m::Module, s::Symbol = :name) = Plain{m}(s)

macro Plain(s::Symbol = :name)
    return esc(:(Glossaries.Plain{@__MODULE__}($s)))
end

# Functor for a term
function (p::Plain)(term::Term, args...; kwargs...)
    return _print(term, p.field, args...; kwargs...)
end
