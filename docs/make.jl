using Documenter
using DeIdenfication

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs==0.17.5", "mkdocs-material==2.9.4"),
    repo = "github.com/bcbi/DeIdentification.jl.git",
    julia  = "0.7",
    osname = "linux"
)
