"""
    GlossarEntry

An abstract type representing a term in a glossary.
"""
abstract type GlossarEntry end

function current_glossary! end

"""
    Glossary{T} <: GlossarEntry

# Fields
* `terms::Dict{Symbol, T}` : A dictionary mapping term names (as symbols) to terms of type `T`.

A glossary containing entries of type `T` where `T` is a subtype of `GlossarEntry`.
Since `Glossary` is a subtype of `GlossarEntry`, glossaries can be nested within other glossaries.

# Constructor
    Glossary(terms = Dict{Symbol, GlossarEntry}(); current = true

Creates a new (empty) `Glossary` instance. Both constructors set the created glossary as the [`current_glossary`](@ref).

## Keyword Arguments
* `current::Bool = true` : whether to set or not to set this new Glossary as new default.
  to avoid setting it as current, use `current = false`, especially when using
  nested glossaries with an outer implicit reference like
  ```
  define!(:SubGlossary, Glossaries.Glossary(;current=false))
  ```
  otherwise the outer one would be equal to the inner one, which would lead to a recursion.
"""
struct Glossary{T <: GlossarEntry} <: GlossarEntry
    terms::Dict{Symbol, T}
    function Glossary(terms::Dict{Symbol, T} = Dict{Symbol, GlossarEntry}(); current = true) where {T <: GlossarEntry}
        glossary = new{T}(terms)
        current && current_glossary!(glossary)
        return glossary
    end
end
