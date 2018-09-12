using Documenter, Capstan

makedocs(modules=[Capstan],
         doctest = false,
         format = :html,
         sitename = "Capstan",
         pages = ["Introduction" => "index.md"])

deploydocs(repo = "github.com/JuliaDiff/Capstan.jl.git",
           osname = "linux",
           julia = "1.0",
           target = "build",
           deps = nothing,
           make = nothing)
