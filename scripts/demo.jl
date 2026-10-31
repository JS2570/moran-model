# Run from the project folder: julia --project=. scripts/demo.jl
include(joinpath(@__DIR__, "..", "src", "MoranModel.jl"))
using .MoranModel
using Random
using Printf

function main()
    N = 5
    i = 2
    s = 0.5
    probabilities = transition_probabilities(N, i, s)
    println("ONE EVENT: N=5, i=2, s=0.5")
    @printf("up = %.3f, down = %.3f, stay = %.3f\n", probabilities.up, probabilities.down, probabilities.stay)
    println("\nA HAND TRACE (specified draws, not a random sample)")
    draws = [0.12, 0.72, 0.41, 0.95, 0.10, 0.03]
    for (event, u) in enumerate(draws)
        probabilities = transition_probabilities(N, i, s)
        i = next_count(i, probabilities.up, probabilities.down, u)
        @printf("event %d: draw %.2f -> i = %d\n", event, u, i)
    end

    println("\nA SEEDED EXPERIMENT: N=100, i0=1, s=0.01")
    rng = MersenneTwister(20261027)
    repetitions = 2000
    fixations = 0
    for repetition in 1:repetitions
        outcome = simulate_fixation(rng, 100, 1, 0.01)
        fixations += outcome.fixed
    end
    interval = wilson_interval(fixations, repetitions)
    @printf("fixations: %d / %d\n", fixations, repetitions)
    @printf("estimate: %.6f\n", fixations / repetitions)
    @printf("95%% Wilson interval: [%.6f, %.6f]\n", interval.lower, interval.upper)
    @printf("exact probability: %.6f\n", fixation_probability(100, 1, 0.01))
end

main()
