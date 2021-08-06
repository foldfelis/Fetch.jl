using Fetch
using Documenter

DocMeta.setdocmeta!(Fetch, :DocTestSetup, :(using Fetch); recursive=true)

makedocs(;
    modules=[Fetch],
    authors="JingYu Ning <foldfelis@gmail.com> and contributors",
    repo="https://github.com/foldfelis/Fetch.jl/blob/{commit}{path}#{line}",
    sitename="Fetch.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://foldfelis.github.io/Fetch.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/foldfelis/Fetch.jl",
    devbranch="main"
)
