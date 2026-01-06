#
# For now this is a placeholder and illustrates how this is supposed to work
#

using Glossaries, Test

# Create a new glossary in the Main module
g = Glossaries.@Glossary()

@testset "Glossaries.jl" begin
    @testset "Defining and Formatting terms" begin
        t = Glossaries.Term("manifold")
        Glossaries.add!(t, :type, "AbstractManifold")
        Glossaries.add!(t, :description, "a Riemannian manifold")
        Glossaries.add!(t, :default, (; n=2) -> "Sphere($n)")
        Glossaries.add!(t, :math, raw"\mathcal M")
        Glossaries.add!(t, :note, " (finite dimensional)")

        s = repr(t)
        @test contains(s, ":default")
        @test contains(s, ":type")
        @test contains(s, ":name")
        @test contains(s, ":math")
        @test contains(s, ":description")

        arg = Glossaries.@Argument(true)
        @test Glossaries.Argument{Main}() === arg
        s2 = arg(t)
        # * `manifold::AbstractManifold`:  a Riemannian manifold
        @test contains(s2, "`manifold::AbstractManifold`")
        @test contains(s2, "a Riemannian manifold")
        @test contains(arg(t; add_properties = [:note]), " (finite dimensional)")

        fld = Glossaries.@Field()
        @test Glossaries.Field{Main}() === fld
        @test Glossaries.Field() === fld
        s4 = fld(t)
        # * `manifold::AbstractManifold`:  a Riemannian manifold
        @test contains(s4, "`manifold::AbstractManifold`")
        @test contains(s4, "a Riemannian manifold")
        @test contains(fld(t; add_properties = [:note]), " (finite dimensional)")

        kw = Glossaries.@Keyword()
        @test Glossaries.Keyword(true) === kw
        @test Glossaries.Keyword{Main}() === kw
        @test Glossaries.Keyword(; show_type = true) === kw
        s4 = kw(t)
        # * `manifold::AbstractManifold = Sphere(2)`:  a Riemannian manifold
        @test contains(s4, "`manifold::AbstractManifold = Sphere(2)`")
        @test contains(s4, "a Riemannian manifold")
        @test contains(kw(t; add_properties = [:note]), " (finite dimensional)")

        p = Glossaries.@Plain()
        @test Glossaries.Plain() === p
        @test Glossaries.Plain{Main}() === p
        s5 = p(t)
        # just prints the name
        @test s5 == "manifold"

        m = Glossaries.Math()
        @test Glossaries.Math{Main}() === m
        s6 = m(t)
        # \mathcal M
        @test contains(s6, raw"\mathcal M")

        mt = Glossaries.MathTerm()
        @test Glossaries.MathTerm{Main}() === mt
        s7 = mt(t)
        # a Riemannian manifold ``\mathcal M``
        @test contains(s7, "a Riemannian manifold")
        @test contains(s7, raw"``\mathcal M``")

        # Define in (current/new) glossary
        g = Glossaries.@define!(:manifold, t)
        @test current_glossary()[:manifold] == t
        Glossaries.@define!(:pkg_name, "Glossaries.jl")
        Glossaries.@define!(:pkg_name, :description, "A Julia package for glossaries.")
        @test arg(:manifold) == arg(t)
        arg(:manifold) # prints the same as above, since we added t to the current glossary
        # List both entries as a list, where Glossaries is printed without type, since we did not set it
        s8 = arg()
        @test contains(s8, "`manifold::AbstractManifold`")
        @test_logs (:warn,) arg(:A)
        @test_logs (:warn,) arg([:A, :manifold])

        s9 = repr(g)
        @test contains(s9, ":manifold")
        @test contains(s9, ":pkg_name")
        @test contains(s9, "Glossary with 2 terms")
        s10 =  Glossaries._print(g; n=3)
        @test contains(s10, "Sphere(3)")
    end
    @testset "Search and replace" begin
        g2 = Glossaries.Glossary()
        Glossaries.define!(Main, g2)
        Glossaries.@define!(:alpha, :math, raw"\alpha")
        Glossaries.@define!(:alpha, :description, "first letter of the Greek alphabet")
        Glossaries.@define!(:beta, :math, raw"\beta")
        Glossaries.@define!(:beta, :description, "second letter of the Greek alphabet")
        Glossaries.@define!(:frakg, :math, raw"\mathfrak{g}")
        @test length(g2("Greek")) == 2
    end
end
