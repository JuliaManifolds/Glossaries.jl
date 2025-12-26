#!/usr/bin/env julia
#
#

if "--help" ∈ ARGS
    println(
        """
        docs/make.jl

        Render the `Glossaries.jl` documentation with optional arguments

        Arguments
        * `--help`              - print this help and exit without rendering the documentation
        * `--prettyurls`        – toggle the pretty urls part to true, which is always set on CI
        * `--quarto`            – (re)run the Quarto notebooks from the `tutorials/` folder before
          generating the documentation. If they are generated once they are cached accordingly.
          Then you can spare time in the rendering by not passing this argument.
          If quarto is not run, some tutorials are generated as empty files, since they
          are referenced from within the documentation.
          These are currently `getstarted.md`.
        """
    )
    exit(0)
end
run_on_CI = (get(ENV, "CI", nothing) == "true")
run_quarto = "--quarto" in ARGS
tutorials_in_menu = true # Change once we have more than the default tutorial
tutorials_menu = "Get started with Glossaries.jl" => "tutorials/getstarted.md"

fn = joinpath(@__DIR__, "src/tutorials/", "getstarted.md")
if (!isfile(fn) || filesize(fn) == 0) && !run_quarto
    @warn "Tutorial Get started with Glossaries.jl does not exist at $fn."
    @warn "Generating empty file, since this tutorial is linked to from the documentation."
    touch(fn)
end

if Base.active_project() != joinpath(@__DIR__, "Project.toml")
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

if run_quarto || run_on_CI
    @info "Rendering Quarto"
    tutorials_folder = (@__DIR__) * "/../tutorials"
    # instantiate the tutorials environment if necessary
    Pkg.activate(tutorials_folder)
    # For a breaking release -> also set the tutorials folder to the most recent version
    Pkg.instantiate()
    Pkg.activate(@__DIR__) # but return to the docs one before
    run(`quarto render $(tutorials_folder)`)
end

using Documenter
using DocumenterCitations, DocumenterInterLinks
using Glossaries

function add_links(line::String, url::String = "https://github.com/JuliaManifolds/Manopt.jl")
    # replace issues (#XXXX) -> ([#XXXX](url/issue/XXXX))
    while (m = match(r"\(\#([0-9]+)\)", line)) !== nothing
        id = m.captures[1]
        line = replace(line, m.match => "([#$id]($url/issues/$id))")
    end
    # replace ## [X.Y.Z] -> with a link to the release [X.Y.Z](url/releases/tag/vX.Y.Z)
    while (m = match(r"\#\# \[([0-9]+.[0-9]+.[0-9]+)\] (.*)", line)) !== nothing
        tag = m.captures[1]
        date = m.captures[2]
        line = replace(line, m.match => "## [$tag]($url/releases/tag/v$tag) ($date)")
    end
    return line
end

generated_path = joinpath(@__DIR__, "src")
base_url = "https://github.com/JuliaManifolds/Manopt.jl/blob/master/"
isdir(generated_path) || mkdir(generated_path)
for (md_file, doc_file) in
    [
        # ("CONTRIBUTING.md", "contributing.md"),
        ("NEWS.md", "news.md"),
    ]
    open(joinpath(generated_path, doc_file), "w") do io
        # Point to source license file
        println(
            io,
            """
            ```@meta
            EditURL = "$(base_url)$(md_file)"
            ```
            """,
        )
        # Write the contents out below the meta block
        for line in eachline(joinpath(dirname(@__DIR__), md_file))
            println(io, add_links(line))
        end
    end
end

bib = CitationBibliography(joinpath(@__DIR__, "src", "references.bib"); style = :alpha)
links = InterLinks()
makedocs(;
    format = Documenter.HTML(;
        prettyurls = run_on_CI || ("--prettyurls" ∈ ARGS),
    ),
    modules = [Glossaries],
    authors = "Ronny Bergmann <ronny.bergmann@ntnu.no> and contributors.",
    sitename = "Glossaries.jl",
    pages = [
        "Home" => "index.md",
        (tutorials_in_menu ? [tutorials_menu] : [])...,
        "Reference" => "reference.md",
        "Changelog" => "news.md",
    ],
    plugins = [bib, links],
)
deploydocs(; repo = "github.com/JuliaManifolds/Glossaries.jl", push_preview = true)
#back to main env
Pkg.activate()
