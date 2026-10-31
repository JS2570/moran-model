# Run after the full study: julia --project=. scripts/prepare_guide.jl
# This only prepares tables and plot inputs. It does not run new experiments.
include(joinpath(@__DIR__, "..", "src", "MoranModel.jl"))
using .MoranModel
using Printf

function read_rows(path)
    lines = readlines(path)
    rows = Vector{Vector{String}}()
    for line in lines[2:end]
        push!(rows, String.(split(line, ",")))
    end
    return rows
end

function main()
    root = normpath(joinpath(@__DIR__, ".."))
    data = joinpath(root, "results", "full")
    target = joinpath(root, "guide", "generated")
    mkpath(target)
    # Keep the LaTeX project self-contained for the app and for Overleaf.
    code_directory = joinpath(root, "guide", "code")
    mkpath(code_directory)
    for source in ["src/MoranModel.jl", "scripts/demo.jl", "scripts/run_study.jl",
                   "scripts/prepare_guide.jl", "test/runtests.jl"]
        cp(joinpath(root, source), joinpath(code_directory, basename(source)); force=true)
    end
    for filename in readdir(data)
        if startswith(filename, "trajectory_N") && endswith(filename, ".csv")
            cp(joinpath(data, filename), joinpath(target, filename); force=true)
        end
    end
    rows = read_rows(joinpath(data, "fixation.csv"))
    length(rows) == 28 || error("Run the complete study first: expected 28 conditions.")
    covered = 0
    total_repetitions = 0
    maximum_standardised_error = 0.0
    for row in rows
        repetitions = parse(Int, row[4])
        repetitions == 20000 || error("The teaching guide requires the full 20,000-repetition study.")
        total_repetitions += repetitions
        estimate = parse(Float64, row[6])
        exact = parse(Float64, row[9])
        covered += parse(Float64, row[7]) <= exact <= parse(Float64, row[8])
        error_in_units_of_se = abs(estimate - exact) / sqrt(exact * (1 - exact) / repetitions)
        maximum_standardised_error = max(maximum_standardised_error, error_in_units_of_se)
    end
    open(joinpath(target, "summary.tex"), "w") do file
        println(file, "\\newcommand{\\StudyRepetitions}{", total_repetitions, "}")
        println(file, "\\newcommand{\\IntervalsCovering}{", covered, "}")
        @printf(file, "\\newcommand{\\MaximumStandardisedError}{%.3f}\n", maximum_standardised_error)
    end
    open(joinpath(target, "selected_table.tex"), "w") do file
        println(file, raw"\begin{tabular}{rrrrl}\toprule")
        println(file, raw"\(s\) & Fixations & Estimate & Exact & 95\% Wilson interval\\\midrule")
        for row in rows
            if parse(Int, row[1]) == 100
                @printf(file, "%.3f & %s & %.4f & %.4f & [%.4f, %.4f] \\\\\n",
                    parse(Float64, row[2]), row[5], parse(Float64, row[6]),
                    parse(Float64, row[9]), parse(Float64, row[7]), parse(Float64, row[8]))
            end
        end
        println(file, raw"\bottomrule\end{tabular}")
    end
    for N in [20, 50, 100, 200]
        open(joinpath(target, "fixation_N$(N).csv"), "w") do file
            println(file, "s,estimate,exact,error_lower,error_upper")
            for row in rows
                if parse(Int, row[1]) == N
                    estimate = parse(Float64, row[6])
                    println(file, join((row[2], estimate, row[9],
                        estimate - parse(Float64, row[7]), parse(Float64, row[8]) - estimate), ","))
                end
            end
        end
        open(joinpath(target, "curve_N$(N).csv"), "w") do file
            println(file, "s,exact")
            for s in range(0.0, 0.1, length=201)
                println(file, s, ",", fixation_probability(N, 1, s))
            end
        end
        approximation_lines = readlines(joinpath(data, "approximation.csv"))
        open(joinpath(target, "approximation_N$(N).csv"), "w") do file
            println(file, approximation_lines[1])
            for line in approximation_lines[2:end]
                if first(split(line, ",")) == string(N)
                    println(file, line)
                end
            end
        end
    end
    open(joinpath(target, "initial_table.tex"), "w") do file
        println(file, raw"\begin{tabular}{rrrr}\toprule")
        println(file, raw"\(N\) & One copy & Initial frequency 10\% & One copy / neutral\\\midrule")
        for row in read_rows(joinpath(data, "initial_frequency.csv"))
            if parse(Float64, row[2]) == 0.01
                @printf(file, "%s & %.4f & %.4f & %.3f \\\\\n", row[1],
                    parse(Float64, row[5]), parse(Float64, row[6]), parse(Float64, row[7]))
            end
        end
        println(file, raw"\bottomrule\end{tabular}")
    end
    println("Prepared guide inputs from ", total_repetitions, " completed repetitions.")
end

main()
