"""
    GlossarEntry

An abstract type representing a term in a glossary.
"""
abstract type GlossarEntry end

"""
    Glossary{T} <: GlossarEntry

# Fields
* `terms::Dict{Symbol, T}` : A dictionary mapping term names (as symbols) to terms of type `T`.

A glossary containing entries of type `T` where `T` is a subtype of [`GlossarEntry`](@ref).
As [`Glossary`](@ref) is a subtype of [`GlossarEntry`](@ref), glossaries can be nested within other glossaries.

# Constructor

    Glossary(terms = Dict{Symbol, GlossarEntry}())

Creates a new (empty) `Glossary` instance.
"""
struct Glossary{T <: GlossarEntry} <: GlossarEntry
    terms::Dict{Symbol, T}
end
Glossary() = Glossary(Dict{Symbol, GlossarEntry}())

"""
    @Glossary

A macro to introduce a glossary in the current Module as well as access functions [`current_glossary`](@ref) and [`current_glossary!`](@ref),
such that one can easily work with the current active glossary in a thread-safe manner.

!!! note

    This macro should be called only once per module, since a second call would overwrite
    the current active glossary in that module, which might cause even an error in Julia 1.11 or before.
"""
macro Glossary()
    return esc(
        quote
            # Adapted from the idea in Makie.jl and their CURRENT_FIGURE
            const _CURRENT_GLOSSARY = Ref{Glossaries.Glossary}(Glossaries.Glossary())
            const _CURRENT_GLOSSARY_LOCK = Base.ReentrantLock()

            current_glossary() = lock(() -> _CURRENT_GLOSSARY[], _CURRENT_GLOSSARY_LOCK)
            current_glossary!(glossary) = lock(() -> (_CURRENT_GLOSSARY[] = glossary), _CURRENT_GLOSSARY_LOCK)
            current_glossary()
        end
    )
end
