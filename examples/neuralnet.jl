####################
# Model Definition #
####################

#=== utilities ===#

sigmoid(x) = one.(x) ./ (one.(x) .+ exp.(-x))
softmax(x) = exp.(x) ./ sum(exp.(x))
cross_entropy(y′, y) = mean(y′ .* -log.(y))

#=== Layer ===#

struct Layer{F}
    f::F
    W::Matrix{Float64}
    b::Vector{Float64}
end

Layer(f, n::Integer, m::Integer) = Layer(f, randn(n, m) / 100, randn(n) / 100)

(l::Layer)(x) = l.W * x + l.b

#=== Model ===#

struct Model
    layers::Vector{Layer}
end

function (m::Model)(label, data)
    for layer in m.layers
        data = layer.f(layer(data))
    end
    return cross_entropy(label, data)
end

#######################
# Model Instantiation #
#######################

layers = [Layer(sigmoid, 100, 100), Layer(sigmoid, 100, 100), Layer(softmax, 100, 100)]
model = Model(layers)
data₁ = rand(100)
label₁ = vcat(1.0, zeros(99))

###############
# Post-Hoc AD #
###############

using Capstan, Test
using Capstan.Reverse: @primitive, @propagate!, value, deriv, Gradient, wrt!, wrt

#=== derivative definitions ===#

@primitive sigmoid(x)
function Capstan.Reverse.back!(::typeof(sigmoid), x, y)
    @propagate!(x, begin
        v = value(x)
        dv = exp.(v) ./ ((exp.(v) .+ one.(v)).^2)
        dv .* deriv(y)
    end)
end

@primitive softmax(x)
function Capstan.Reverse.back!(::typeof(softmax), x, y)
    @propagate!(x, begin
        v = value(x)
        sv = softmax(v)
        dv = similar(sv, length(sv), length(sv))
        for i in eachindex(sv), j in eachindex(sv)
            dv[i, j] = sv[i] * ((i == j) - sv[j])
        end
        dv' * deriv(y)
    end)
end

@primitive cross_entropy(y′, y)
function Capstan.Reverse.back!(::typeof(cross_entropy), y′, y, z)
    @propagate!(y′, begin
        vy = value(y)
        -(log.(vy) ./ length(vy)) .* deriv(z)
    end)
    @propagate!(y,  begin
        vy′ = value(y′)
        vy = value(y)
        -(vy′ ./ (vy .* length(vy))) .* deriv(z)
    end)
end

#=== setup AD ===#

# instantiate a version of model that will do AD on top of the original computation
∇model = Gradient(model)

# mark the differentiable variables
for layer in layers
    wrt!(∇model, layer.W)
    wrt!(∇model, layer.b)
end

#=== execute model + AD ===#

# evaluate the model + calculate gradients
result = ∇model(label₁, data₁)
@test result == model(label₁, data₁)

# query the model for a gradient of a differentiable variable
∇W₂ = wrt(∇model, layers[2].W)
