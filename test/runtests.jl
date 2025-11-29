#
# For now this is a placeholder and illustrates how this is supposed to work
#

using Glossaries, Test

t = Glossaries.Term("manifold")
Glossaries.define!(t, :type, "AbstractManifold")
Glossaries.define!(t, :description, " a Riemannian manifold")
Glossaries.define!(t, :default, "Sphere(2)")
Glossaries.define!(t, :math, raw"\mathcal M")

arg = Glossaries.Argument(true)
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
