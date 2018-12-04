using Documenter
using DeIdentification

makedocs(
    modules = [ DeIdentification ],
    assets = [
        "assets/facicon.ico",
        "assets/bcbi.css",
        "assets/logo.png"
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
