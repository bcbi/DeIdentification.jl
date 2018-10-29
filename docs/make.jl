using Documenter
using DeIdenfication

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs==0.17.5", "mkdocs-material==2.9.4"),
    repo = "github.com/bcbi/DeIdenfication.jl.git",
    julia  = "1.0",
    osname = "linux"
)
