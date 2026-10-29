# @NAME@ (equivalence check template)

Two versions of one module, `gold.v` (reference) and `gate.v` (optimised or refactored), and two yosys proofs that
they are equal for every input: `equiv.ys` (equiv_make / equiv_simple / equiv_induct, also for registers) and
`miter.ys` (miter + SAT, good for arithmetic). Use it after a refactor or a hand optimisation.

```sh
fpga-box shell -- make test     # exit status 1 and the failing input when they differ
```
