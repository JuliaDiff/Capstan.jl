module Reverse

import ..Capstan
import Cassette
import Cassette: Box, isboxed, unbox, meta, overdub, @context
import Base: RefValue

@context RDiffCtx

include("utilities.jl")
include("variables.jl")
include("tape.jl")
include("gradient.jl")
include("primitives.jl")

end # module
