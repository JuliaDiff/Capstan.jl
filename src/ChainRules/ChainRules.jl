module ChainRules

using Base.Broadcast: materialize, broadcasted

include("markup.jl")
include("rules.jl")
include("defaults/variables.jl")
include("defaults/functions.jl")

end # module
