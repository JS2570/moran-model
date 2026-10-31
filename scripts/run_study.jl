# Run from the project folder: julia --project=. scripts/run_study.jl
# For a faster check: julia --project=. scripts/run_study.jl --quick
include(joinpath(@__DIR__, "..", "src", "MoranModel.jl"))
using .MoranModel
using Random
using Printf
using Dates

# 1. A small helper writes one row of comma-separated values.
function write_row(file, values)
    println(file, join(values, ","))
end

# 2. Repeat the experiment for the fixed parameter grid.
function run_fixation_grid(output_directory, repetitions, base_seed)
    output_path = joinpath(output_directory, "fixation.csv")
    open(output_path, "w") do file
        println(file, "N,s,i0,repetitions,fixations,estimate,lower,upper,exact,standard_error,events_mean,seed")
        cell = 0
        for N in [20, 50, 100, 200]
            for s in [0.0, 0.001, 0.005, 0.01, 0.02, 0.05, 0.1]
                cell += 1
                seed = base_seed + cell
                rng = MersenneTwister(seed)
                fixations = 0
                total_events = 0
                for repetition in 1:repetitions
                    outcome = simulate_fixation(rng, N, 1, s)
                    fixations += outcome.fixed
                    total_events += outcome.events
                end
                estimate = fixations / repetitions
                interval = wilson_interval(fixations, repetitions)
                exact = fixation_probability(N, 1, s)
                standard_error = sqrt(estimate * (1 - estimate) / repetitions)
                write_row(file, (N, s, 1, repetitions, fixations, estimate,
                    interval.lower, interval.upper, exact, standard_error,
                    total_events / repetitions, seed))
                flush(file)
                @printf("cell %2d/28: N=%3d s=%.3f estimate=%.6f exact=%.6f\n", cell, N, s, estimate, exact)
            end
        end
    end
end

# 3. Compare one copy with an initial frequency of ten percent, analytically.
function write_initial_frequency_comparison(output_directory)
    open(joinpath(output_directory, "initial_frequency.csv"), "w") do file
        println(file, "N,s,i0,initial_frequency,exact_single,exact_ten_percent,relative_to_neutral_single")
        for N in [20, 50, 100, 200]
            for s in [0.0, 0.001, 0.005, 0.01, 0.02, 0.05, 0.1]
                i0 = div(N, 10)
                single = fixation_probability(N, 1, s)
                multiple = fixation_probability(N, i0, s)
                write_row(file, (N, s, i0, i0 / N, single, multiple, N * single))
            end
        end
    end
end

# 4. Measure the error in the weak-selection approximation.
function write_approximation_comparison(output_directory)
    open(joinpath(output_directory, "approximation.csv"), "w") do file
        println(file, "N,s,Ns,exact,approximation,relative_error")
        selection_values = 10.0 .^ range(log10(1e-5), log10(0.5), length=121)
        for N in [20, 50, 100, 200]
            for s in selection_values
                exact = fixation_probability(N, 1, s)
                approximation = s / (-expm1(-N * s))
                relative_error = abs(approximation - exact) / exact
                write_row(file, (N, s, N * s, exact, approximation, relative_error))
            end
        end
    end
end

# 5. Save eight preselected histories per condition for plotting.
function write_trajectories(output_directory, base_seed)
    N = 100
    max_events = 30000
    sample_every = 100
    paths_per_condition = 8
    condition = 0
    summary_path = joinpath(output_directory, "trajectory_summary.csv")
    open(summary_path, "w") do summary
        println(summary, "N,i0,s,path,seed,absorbed,absorbed_at,final_count")
        for i0 in [1, 10]
            for s in [0.0, 0.01, 0.1]
                condition += 1
                paths = Vector{Vector{Int}}()
                for path_number in 1:paths_per_condition
                    seed = base_seed + 100000 + 100condition + path_number
                    trajectory = simulate_trajectory(MersenneTwister(seed), N, i0, s, max_events)
                    push!(paths, trajectory.counts)
                    absorbed_at = trajectory.absorbed_at
                    if absorbed_at === nothing
                        absorbed_at = -1
                    end
                    write_row(summary, (N, i0, s, path_number, seed,
                        trajectory.absorbed, absorbed_at, trajectory.counts[end]))
                end
                deterministic = deterministic_trajectory(N, i0, s, max_events)
                selection_label = replace(string(s), "." => "p")
                filename = "trajectory_N$(N)_i$(i0)_s$(selection_label).csv"
                open(joinpath(output_directory, filename), "w") do file
                    println(file, "event,generation,path_1,path_2,path_3,path_4,path_5,path_6,path_7,path_8,deterministic")
                    for event in 0:sample_every:max_events
                        row = Float64[event, event / N]
                        for counts in paths
                            push!(row, counts[event + 1] / N)
                        end
                        push!(row, deterministic[event + 1])
                        write_row(file, row)
                    end
                end
            end
        end
    end
end

# 6. Save the information needed to reproduce the run.
function write_metadata(output_directory, repetitions, base_seed, elapsed_seconds, quick)
    open(joinpath(output_directory, "metadata.txt"), "w") do file
        println(file, "Moran model simulation study")
        println(file, "Julia version: ", VERSION)
        println(file, "Random generator: Random.MersenneTwister")
        println(file, "Base seed: ", base_seed)
        println(file, "Cell seeds: base_seed + cell, in N-then-s loop order")
        println(file, "Trajectory seeds: base_seed + 100000 + 100*condition + path_number")
        println(file, "Population sizes: 20, 50, 100, 200")
        println(file, "Selection advantages: 0, 0.001, 0.005, 0.01, 0.02, 0.05, 0.1")
        println(file, "Initial copies for simulation study: 1")
        println(file, "Repetitions per cell: ", repetitions)
        println(file, "Quick demonstration mode: ", quick)
        println(file, "No external Julia packages are required.")
        println(file, "Every fixation experiment runs until loss or fixation.")
        println(file, "Trajectory display horizon: 30000 events; 100 events per plotted generation.")
        println(file, "trajectory_summary absorbed_at=-1 means unfinished at the display horizon.")
        println(file, "Elapsed seconds: ", elapsed_seconds)
        println(file, "Completed UTC: ", Dates.now(Dates.UTC))
    end
end

# 7. Choose a run mode, then generate all the data.
function main()
    quick = "--quick" in ARGS
    unknown = setdiff(ARGS, ["--quick"])
    isempty(unknown) || error("Unknown arguments: $(join(unknown, ", "))")
    repetitions = 20000
    mode = "full"
    if quick
        repetitions = 1000
        mode = "demo"
    end
    base_seed = 20261027
    output_directory = normpath(joinpath(@__DIR__, "..", "results", mode))
    mkpath(output_directory)
    start_time = time()
    run_fixation_grid(output_directory, repetitions, base_seed)
    write_initial_frequency_comparison(output_directory)
    write_approximation_comparison(output_directory)
    write_trajectories(output_directory, base_seed)
    elapsed_seconds = time() - start_time
    write_metadata(output_directory, repetitions, base_seed, elapsed_seconds, quick)
    @printf("Finished in %.2f seconds. Data: %s\n", elapsed_seconds, output_directory)
end

main()
