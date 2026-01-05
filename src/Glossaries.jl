"""
🗃️ Glossaries.jl – manage a glossary for arguments, keywords and other snippets and terms for
  the documentation of your Julia package.

A Julia package for managing glossaries of terms, including their metadata,
for example their mathematical notation.

The package further provides several formatting options for displaying terms
in different contexts, e.g., as function arguments or keyword arguments or within mathematical formulas.

* 📚 Documentation: [juliamanifolds.github.io/Glossaries.jl/](https://juliamanifolds.github.io/Glossaries.jl/)
* 📦 Repository: [github.com/JuliaManifolds/Glossaries.jl](https://github.com/JuliaManifolds/Glossaries.jl)
* 💬 Discussions: [github.com/JuliaManifolds/Glossaries.jl/discussions](https://github.com/JuliaManifolds/Glossaries.jl/discussions)
* 🎯 Issues: [github.com/JuliaManifolds/Glossaries.jl/issues](https://github.com/JuliaManifolds/Glossaries.jl/issues)
"""
module Glossaries

include("base_types.jl")

include("terms.jl")
include("format.jl")
include("search.jl")

@Glossary()

end # module Glossaries
