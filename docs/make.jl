using Documenter
using DeIdentification

makedocs(
    modules = [ DeIdentification ],
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
