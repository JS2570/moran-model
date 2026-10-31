# Verification record

Original study completed on 27 October 2026; model tests rerun successfully on 31 October 2026.

- Julia 1.13.1; no external Julia packages required.
- 1,925 automated checks passed. See `results/test_summary.txt`.
- The full experiment completed 560,000 fixation-or-loss simulations across 28 conditions, with 20,000 repetitions per condition.
- Exact fixation probabilities agree with an independent numerical solution of the backward recurrence.
- Neutrality, absorbing boundaries, event probabilities, numerical stability, deterministic drift, seeds and Wilson intervals were checked.
- 27 of 28 nominal 95% intervals contain their exact probabilities. The retained miss is not removed or replaced.

Run the checks with:

```sh
julia --project=. test/runtests.jl
```
