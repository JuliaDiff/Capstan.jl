module ChainRules

using Base.Broadcast: materialize, broadcasted

include("markup.jl")
include("interface.jl")
include("defaults/interface.jl")
include("defaults/rules.jl")

end # module
