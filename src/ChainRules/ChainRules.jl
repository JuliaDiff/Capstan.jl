module ChainRules

#=
TODO:
    - obviously more `rule`s, `layout`s, and `description`s
    - macros implementations: `@sig`, `@sigtype`, `@forward_chain`, `@reverse_chain!`
    - interface overloadability design pass
=#

include("markup.jl")
include("properties.jl")
include("defaults/variables.jl")
include("defaults/functions.jl")

end # module
