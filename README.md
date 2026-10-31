# Learn selection and genetic drift in Julia

**Start with [the teaching guide](guide/main.pdf), Chapter 1.** It assumes no population genetics or Julia knowledge. Work through the five-individual example before running the larger study. The short application report is deliberately deferred.

This is a worked investigation of the established Moran model. It is a teaching resource, not a claim of a new biological result.

## What is included

| Item | Purpose |
| --- | --- |
| `guide/main.pdf` | The complete step-by-step self-study guide, with worked exercises and solutions. |
| `guide/main.tex` and `guide/chapters/` | Editable LaTeX source. |
| `src/MoranModel.jl` | Nine small functions implementing and checking the model. |
| `scripts/demo.jl` | One event, a manual trace, and a small seeded experiment. |
| `scripts/run_study.jl` | Full study, or a separate quick demonstration. |
| `scripts/prepare_guide.jl` | Convert the full-study CSV files into plot inputs and printed tables. |
| `test/runtests.jl` | Automated checks of the model and calculations. |
| `results/full/` | Actual full-study data, seeds, metadata and console log. |
| `results/demo/` | Separate quick-run data; these are not the full-study results. |
| `results/test_summary.txt` | The completed test run: 1,925 checks passed. |
| `results/demo_output.txt` | Expected output of the supplied small demonstration in the recorded environment. |
| `Project.toml`, `Manifest.toml` | Julia environment and exact resolved standard-library versions. |

## First run

Julia **1.13.1** was used for the supplied results. No external Julia packages are required. Julia installation instructions are available from the [official Julia website](https://julialang.org/install/).

1. Extract the ZIP, if using the ZIP.
2. Open a terminal and change into the extracted `moran_project` folder. One way on a Mac is to type `cd `, drag the folder into the terminal, and press Return.
3. Run these commands in the terminal, not inside Julia's `julia>` prompt:

```sh
julia --version
julia --project=. scripts/demo.jl
julia --project=. test/runtests.jl
```

The demo first prints `up = 0.300, down = 0.200, stay = 0.500`. Its supplied hand draws produce counts `3, 3, 2, 2, 3, 4`. These deliberately specified draws are a teaching trace, not a random sample. Its separate seeded experiment gives 33 fixations in 2,000 repetitions in the recorded Julia environment.

## Run the study yourself

```sh
julia --project=. scripts/run_study.jl --quick
```

This uses 1,000 repetitions per condition and writes to `results/demo/`.

```sh
julia --project=. scripts/run_study.jl
julia --project=. scripts/prepare_guide.jl
```

The full run uses 20,000 repetitions in each of 28 conditions: 560,000 completed experiments. It writes to `results/full/`. Running it again replaces those generated files. Keep a copy first if you want to preserve your own modified experiment. The preparation helper accepts only the complete full study.

The full grid is `N = [20, 50, 100, 200]`, `s = [0, .001, .005, .01, .02, .05, .1]`, with one initial copy. Each experiment runs until fixation or loss. The separate displayed histories have 30,000-event horizons and are saved every 100 events. Seeds are recorded in the files and in metadata. The same recorded Julia environment and seeds reproduce the scientific numbers; elapsed times and completion timestamps naturally differ.

## Rebuild the PDF

You do **not** need LaTeX to read the supplied PDF or run the Julia model.

If Tectonic is available, run the data-preparation command above, then:

```sh
cd guide
tectonic --keep-logs main.tex
```

The default output is `guide/main.pdf`. Alternatively, open the `guide` folder in Codex's LaTeX editor. The preparation script makes this folder self-contained: it copies the actual runnable source into `guide/code/` and the plotted data into `guide/generated/`. These source copies are verified byte-for-byte. For Overleaf, upload the contents of `guide`, choose `main.tex` as the main document, and use pdfLaTeX. LaTeX plots the generated data with PGFPlots; no external Julia plotting package is needed.

## Read the data correctly

`fixation.csv` contains `N`, `s`, `i0`, `repetitions`, `fixations`, `estimate`, `lower`, `upper`, `exact`, `standard_error`, `events_mean`, and `seed`.

- `estimate` is fixations divided by repetitions.
- `lower` and `upper` are two-sided 95% Wilson interval endpoints.
- `exact` is the exact probability under this model.
- `standard_error` is a plug-in estimate using the observed proportion, not the exact probability.
- `events_mean` averages time until either loss or fixation, across **all** repetitions. It is not the mean time conditional on fixation.

The trajectory column `generation` means `event / N`, a generation-like time convention. It does not represent discrete nonoverlapping biological generations. `path_1` through `path_8` are frequencies, not counts. `deterministic` is a mean-field comparison, not generally the exact average of stochastic histories. In `trajectory_summary.csv`, `absorbed_at = -1` means unfinished at the display horizon; it does not mean loss. All 48 supplied displayed paths happened to absorb within the horizon.

`initial_frequency.csv` is analytical. It compares one starting copy with a fixed 10% starting frequency. `approximation.csv` is also analytical; it records absolute relative error of a weak-selection expression. It is not another simulation experiment.

## Main supplied result

For `N = 100`, `s = .01` and one initial copy, the full study produced **332 / 20,000 = .0166** fixation. The exact probability is **.01570865656**; the Wilson interval is **[.01491983882, .01846582164]**. Selection improves on the neutral probability `.01`, but loss remains the overwhelmingly likely outcome. Chapter 9 explains this in detail.

Across the 28 conditions, 27 nominal 95% intervals contain their exact model probability. The missed interval is retained and discussed; seeds were not chosen to make every interval cover.

## References

The guide cites [McCandlish, Epstein and Plotkin (2015)](https://arxiv.org/abs/1312.1673), the [Julia documentation](https://docs.julialang.org/en/v1/), and the [NIST explanation of Wilson confidence intervals](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm). The guide explicitly translates the reference paper's log-fitness convention into this project's relative-fitness advantage.
