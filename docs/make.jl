using Documenter
using DeIdentification

makedocs(
    modules = [ DeIdentification ],
    sitename = "DeIdentification.jl",
    debug = true,
    pages = [
        "Home" => "index.md",
        "Manual" => "documentation.md"
        ]
    )

deploydocs(
    repo = "github.com/bcbi/DeIdentification.jl.git"
)
