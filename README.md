# Capstan

Cassette-based automatic differentiation for the Julia language.

**Right now, this package is simply a proof-of-concept that was built on an earlier prototype of Cassette.**

Now that an initial version of Cassette has been released, work on a more serious implementation of Capstan has begun. Since Cassette's contextual tagging system (on which Capstan relies) depends on as-of-yet unimplemented compiler optimizations/bug fixes to obtain reasonable performance, Capstan will likely not see an initial release until several minor version bumps into the Julia 1.x release cycle.

Planned features for an initial release include:

- no user-visible cumbersome custom array/number types
- works even with concrete dispatch/structural type constraints
- official support for complex differentiation
- safe nested/higher-order differentiation
- API for custom perturbation/sensitivity seeding
- user-extensible scalar and tensor derivative definitions
- mixed-mode fused broadcast optimizations
- configurable dynamic and static execution modes

Planned features for future releases include:

- support for both GPU and CPU
- higher-order sparsity exploitation (edge-pushing)
- per-region dynamism for subgraphs
