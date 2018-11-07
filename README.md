# Capstan

Cassette-based automatic differentiation for the Julia language.

**The implementation here is currently a WIP; the majority of the planned implementation does not even exist yet. Code may be added, removed, and changed daily. Try things out at your own risk, YMMV, etc.**

Now that an initial version of Cassette has been released, work on a more serious implementation of Capstan has begun. Since Cassette's contextual tagging system (on which Capstan will rely) depends on as-of-yet unimplemented compiler optimizations/bug fixes to obtain reasonable performance, Capstan will likely not see an initial release until several minor version bumps into the Julia 1.x release cycle.

It's likely that not all of these features will make it into an initial release, but planned features include:

- forward-, reverse-, and [mixed-mode](https://arxiv.org/abs/1810.08297) operation
- no cumbersome custom array/number types
- works even with concrete dispatch/structural type constraints
- official support for complex differentiation
- safe nested/higher-order differentiation
- API for custom perturbation/sensitivity seeding
- user-extensible scalar and tensor derivative definitions
- configurable dynamic and static execution modes
- support for both GPU and CPU
- higher-order sparsity exploitation (edge-pushing)
- per-region dynamism for subgraphs

Capstan's codebase follows the [YASGuide](https://github.com/jrevels/YASGuide).
