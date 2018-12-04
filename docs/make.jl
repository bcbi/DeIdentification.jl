using Documenter
using DeIdentification

makedocs(
    modules = [ DeIdentification ],
    assets = [
        "https://github.com/bcbi/code_style_guide/tree/master/assets/favicon.ico",
        "assets/bcbi.css"
        ],
    sitename = "DeIdentification.jl",
    debug = true,
    pages = [
        "Home" => "index.md",
        "Guide" => "usage.md",
        "API" => "documentation.md"
        ]
    )

deploydocs(
    repo = "github.com/bcbi/DeIdentification.jl.git"
)
