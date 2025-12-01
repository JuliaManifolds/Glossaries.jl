#
# For now this is a placeholder and illustrates how this is supposed to work
#

using Glossaries, Test

Glossaries.@Glossary

t = Glossaries.Term("manifold")
Glossaries.add!(t, :type, "AbstractManifold")
Glossaries.add!(t, :description, "a Riemannian manifold")
Glossaries.add!(t, :default, "Sphere(2)")
Glossaries.add!(t, :math, raw"\mathcal M")

arg = Glossaries.@Argument(true)
println(arg(t)) #print as argument:
# * `manifold::`[`AbstractManifold`](@ref):  a Riemannian manifold
kw = Glossaries.Keyword(true)
println(kw(t)) #print as keyword:
# * `manifold::`[`AbstractManifold`](@ref)` = Sphere(2)`:  a Riemannian manifold
p = Glossaries.Plain()
println(p(t)) #print as plain:
# manifold

m = Glossaries.Math()
println(m(t)) #print as math:
# \mathcal M
mt = Glossaries.MathTerm()
println(mt(t)) #print as math:
# a Riemannian manifold ``\mathcal M``

# Define in (current/new) glossary
g = Glossaries.@define!(:manifold, t)
g = Glossaries.@define!(:pkg_name, "Glossaries.jl")
Glossaries.@define!(:pkg_name, :description, "A Julia package for glossaries.")
arg(:manifold) # prints the same as above, since we added t to the current glossary
# but we can also print all from current
arg() |> print
