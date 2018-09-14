# The Goal

Most AD frameworks require some combination of the following from the user:

- pick an API function whose assumptions on input/output shape/type matches the
properties of the target function <--- ForwardDiff/ReverseDiff
- deal with cumbersome wrapper types which are propagated through target code <-- ForwardDiff/ReverseDiff
- specify the target program in the AD tool's DSL. <--- PyTorch, TensorFlow, !(ForwardDiff/ReverseDiff)

Capstan should allow the user to "build" a "plan" which produces a "perfect" API function
for their use case, and should not require b) or c).

# Questions One Asks When Using An AD Tool or Planning/Optimizing An AD Use Case

- Which input/output pairs am I differentiating w.r.t.?
- What is each derivative's order?
- What parts of the differentiation plan will change between uses? What parts are mutable vs.
what parts require instantiating a new plan?
- How do I construct a plan such that construction cost is negligible compared to computation
cost?
- How do I decide which optimizations on the plan are worth it? How do I prescribe
optimizations I know I need?
- How do I prescribe memory for input/seed values?
- How do I populate memory for input/seed values?
- What properties of desired computation are discoverable, vs. what properties need to be
described?
- How do I give hints to otherwise discoverable properties via plan construction?
- Many properties are "subgraph-specific". How do I identify and prescribe properties to
subgraphs?
- What parts of my CG are data-dependent (dynamic vs. static)?
- What parts of the CG can be reduced via higher-order sparsity exploitation?
- How do I schedule checkpointing-style optimizations for specific subgraphs?
- What parts of my CG should run on which device?
- What are my memory constraints for each part of the CG?
- How do I overload a pre/post-processing hook for a specific gradient?
- How do I get the results prescribed by the plan?
- How do I identify efficiently differentiable regions? What regions are not differentiable?

# Decisions

```julia
# some variables
local x1, x2, x3, x4, x5

# `output_selector_function` takes in all output of `f`, and then
# returns the output values that you'd like to differentiate w.r.t.;
# it can return anything passed into it.
# TODO: input selector function?
plan = DiffPlan(f,
                (WrtArg(Scalar()), Fixed(), WrtArg(Tensor()), Fixed()),
                output_selector)

# w.r.t. some "implicit" inputs
wrt!(plan, x4)
wrt!(plan, x5)

exec = compile(plan)::DiffExecutable
seedinput!(exec, x4, ...)
seedoutput!(exec, index_of_output_item, ...)
values = exec(Seeded(x1, s1), x2, Seeded(x3, s3))

wrt(exec, 1)
```


# Implicit vs. Explicit Inputs/Outputs

An explicit input value to a function is a value bound directly to a named argument of a
function, for example:

```
# both x and y here are explicit input values
f(x, y)
```

An explicit output value of a function is a value in `return` statement position within the
function, for example:

```
global z = 1

function f(x, y)
    if x < 0
        return x * y, y # these are explicit return values
    elseif x > 10
        for i in 1:x
            if y < x
                y += z
                z += 1
            else
                return y # this is an explicit return value
            end

    end
    x / y # this is an explicit return value
end
```

An implicit input value is any value the program utilizes in its computation (e.g. `x[1]`,
`z`). So, explicit input values are implicit input values, but the reverse is not true.

An implicit output value is any value computed by the function for a given invocation (e.g.
`z`).

Maybe "given" values and "computed" values are better terms? "Independent" and "dependent"
are bad terms, since "dependent" values may not actually depend on anything (constants).
