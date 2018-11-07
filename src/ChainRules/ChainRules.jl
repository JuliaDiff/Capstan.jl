module ChainRules

using Base.Broadcast: materialize, broadcasted

#=
TODO:
    - obviously more `rule`s, `layout`s, and `description`s
    - macros implementations: `@sig`, `@sigtype`
    - interface overloadability design pass
=#

include("markup.jl")
include("rules.jl")
include("defaults/variables.jl")
include("defaults/functions.jl")

end # module
