# Capstan

Cassette-based automatic differentiation for the Julia language.

Right now, this package is simply a proof-of-concept. It generally will not be usable by normal users until a stable version of Cassette is released (hopefully in the Julia 1.x timeframe). It also is not necessarily kept up-to-date with the latest version of Cassette.

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
