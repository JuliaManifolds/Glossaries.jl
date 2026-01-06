#
# For now this is a placeholder and illustrates how this is supposed to work
#

using Glossaries, Test

# Create a new glossary in the Main module
g = Glossaries.@Glossary()

@testset "Defining and Formatting terms" begin
    t = Glossaries.Term("manifold")
    Glossaries.add!(t, :type, "AbstractManifold")
    Glossaries.add!(t, :description, "a Riemannian manifold")
    Glossaries.add!(t, :default, "Sphere(2)")
    Glossaries.add!(t, :math, raw"\mathcal M")

    s = repr(t)
    @test contains(s, ":default")
    @test contains(s, ":type")
    @test contains(s, ":name")
    @test contains(s, ":math")
    @test contains(s, ":description")

    arg = Glossaries.@Argument(true)
    s2 = arg(t)
    # * `manifold::AbstractManifold`:  a Riemannian manifold
    @test contains(s2, "`manifold::AbstractManifold`")
    @test contains(s2, "a Riemannian manifold")

    kw = Glossaries.Keyword(true)
    s3 = kw(t)
    # * `manifold::AbstractManifold = Sphere(2)`:  a Riemannian manifold
    @test contains(s3, "`manifold::AbstractManifold = Sphere(2)`")
    @test contains(s3, "a Riemannian manifold")

    p = Glossaries.Plain()
    s4 = p(t)
    # just prints the name
    @test s4 == "manifold"

    m = Glossaries.Math()
    s5 = m(t)
    # \mathcal M
    @test contains(s5, raw"\mathcal M")

    mt = Glossaries.MathTerm()
    s6 = mt(t)
    # a Riemannian manifold ``\mathcal M``
    @test contains(s6, "a Riemannian manifold")
    @test contains(s6, raw"``\mathcal M``")

    # Define in (current/new) glossary
    g = Glossaries.@define!(:manifold, t)
    @test current_glossary()[:manifold] == t
    Glossaries.@define!(:pkg_name, "Glossaries.jl")
    Glossaries.@define!(:pkg_name, :description, "A Julia package for glossaries.")
    @test arg(:manifold) == arg(t)
    arg(:manifold) # prints the same as above, since we added t to the current glossary
    # List both entries as a list, where Glossaries is printed without type, since we did not set it
    s7 = arg()
    @test contains(s7, "`manifold::AbstractManifold`")
end
