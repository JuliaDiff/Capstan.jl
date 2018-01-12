# Capstan

A WIP Cassette-based automatic differentiation package for the Julia language.

This package is a prototype, and generally will not be usable by normal users until a stable
version of Cassette is released (hopefully in the Julia 1.x timeframe).

Capstan takes the stance that users should only ever have to think about
the differentiability of their *algorithms*, not their *code*.

Planned features include:

- forward-mode and reverse-mode operation
- mixed-mode fused broadcast optimizations
- works even with Julia code containing concrete dispatch/structural type constraints
- works both on GPU and CPU
- user-extensible scalar and tensor derivative definitions
- API for custom perturbation seeding
- configurable dynamic and static execution modes
- nested/higher-order differentiation
- tape-level sparsity optimizations
- modular graph and variable storage formats
