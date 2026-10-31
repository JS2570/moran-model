# Selection and genetic drift in the Moran model

A reproducible Julia investigation of when an advantageous allele can still be lost in a finite population. This project studies an established model; it does not claim a new biological discovery.

## Model

The population contains `N` haploid individuals of two genetic types. The advantageous type has relative reproductive fitness `1+s`; the other has fitness `1`. Each event selects a parent proportional to fitness and independently selects an individual for replacement. Population size stays fixed, with no further mutation.

Starting from `i` advantageous individuals, the exact fixation probability is

```text
P_fix(i) = [1 - (1+s)^(-i)] / [1 - (1+s)^(-N)]
P_fix(i) = i/N when s = 0
```

The simulations are checked against this result and an independent numerical solution of the backward recurrence.

## Run

Julia 1.13.1 was used for the recorded results. No external Julia packages are required.

```sh
julia --project=. scripts/demo.jl
julia --project=. test/runtests.jl
julia --project=. scripts/run_study.jl --quick
```

For the full study:

```sh
julia --project=. scripts/run_study.jl
```

The quick run writes to `results/demo/`; the full run writes to `results/full/`. Re-running replaces the corresponding generated files.

## Study and results

The full study uses one initial copy, `N = [20, 50, 100, 200]` and `s = [0, .001, .005, .01, .02, .05, .1]`, with 20,000 repetitions per condition: **560,000 completed experiments**. Every fixation experiment runs until loss or fixation. Seeds and environment details are recorded alongside the data.

For `N = 100` and `s = .01`, the study recorded **332 fixations in 20,000 runs (0.0166)**. The exact probability is **0.01570865656**, and the 95% Wilson interval is **[0.01491983882, 0.01846582164]**. Selection improves on the neutral probability of 0.01, while loss remains overwhelmingly likely.

Across all 28 conditions, 27 nominal 95% intervals contain the exact probability. The remaining interval is retained; simulations were not selected to force complete coverage.

## Files

| Path | Contents |
| --- | --- |
| `src/MoranModel.jl` | Model, exact probabilities and supporting calculations |
| `scripts/demo.jl` | Small worked demonstration |
| `scripts/run_study.jl` | Quick and full simulation studies |
| `test/runtests.jl` | 1,925 checks of probabilities, boundaries, recurrence and simulations |
| `results/full/` | Full-study data, seeds, metadata and log |
| `results/demo/` | Separate quick-run results |
| `results/test_summary.txt` | Recorded test output |
| `Project.toml`, `Manifest.toml` | Julia environment |

`fixation.csv` contains simulation estimates, exact probabilities and Wilson confidence intervals. `events_mean` is the mean time until either loss or fixation, across all repetitions. Displayed trajectories have a separate finite horizon; unfinished trajectories are not classified as losses. The deterministic comparison is a mean-field approximation, not generally the exact average of stochastic histories.

## Limitations and reference

The model assumes a well-mixed population, constant selection, fixed population size and no mutation after initialization. It excludes spatial structure, changing environments and real genetic data.

See [McCandlish, Epstein and Plotkin (2015)](https://arxiv.org/abs/1312.1673). Their log-fitness convention differs from the relative-fitness advantage used here: log-fitness is `log(1+s)`.
