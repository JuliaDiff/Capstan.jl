module Forward

import ..Capstan
import Cassette
import DiffRules

############################
# forward-mode OO-based AD #
############################

Cassette.@context FDiffCtx

for (M, f, arity) in DiffRules.diffrules()
    M == :Base || continue
    if arity == 1
        dfdx = DiffRules.diffrule(M, f, :vx)
        @eval begin
            Cassette.@primitive ctx::FDiffCtx function (::typeof($f))(x::@Box)
                vx, dx = Cassette.unbox(ctx, x), Cassette.meta(ctx, x)
                return Cassette.Box(ctx, $f(vx), propagate($dfdx, dx))
            end
        end
    elseif arity == 2
        dfdx, dfdy = DiffRules.diffrule(M, f, :vx, :vy)
        @eval begin
            Cassette.@primitive ctx::FDiffCtx function (::typeof($f))(x::@Box, y::@Box)
                vx, dx = Cassette.unbox(ctx, x), Cassette.meta(ctx, x)
                vy, dy = Cassette.unbox(ctx, y), Cassette.meta(ctx, y)
                return Cassette.Box(ctx, $f(vx, vy), propagate($dfdx, dx, $dfdy, dy))
            end
            Cassette.@primitive ctx::FDiffCtx function (::typeof($f))(x::@Box, vy)
                vx, dx = Cassette.unbox(ctx, x), Cassette.meta(ctx, x)
                return Cassette.Box(ctx, $f(vx, vy), propagate($dfdx, dx))
            end
            Cassette.@primitive ctx::FDiffCtx function (::typeof($f))(vx, y::@Box)
                vy, dy = Cassette.unbox(ctx, y), Cassette.meta(ctx, y)
                return Cassette.Box(ctx, $f(vx, vy), propagate($dfdy, dy))
            end
        end
    end
end

propagate(dfdx::Number, dx::AbstractVector) = dfdx * dx

propagate(dfdx::Number, dx::AbstractVector, dfdy::Number, dy::AbstractVector) = propagate(dfdx, dx) + propagate(dfdy, dy)

#######################################
# half-assed API for testing purposes #
#######################################

function diff(f, x)
    ctx = FDiffCtx(f)
    @assert Capstan.isscalar(x)
    y = Cassette.overdub(ctx, f)(Cassette.Box(ctx, x, [one(x)]))
    @assert Capstan.isscalar(y)
    return Cassette.hasmeta(ctx, y) ? Cassette.meta(ctx, y)[] : zero(Cassette.unbox(ctx, y))
end

end # module
