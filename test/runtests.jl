include(joinpath(@__DIR__, "..", "src", "MoranModel.jl"))
using .MoranModel
using Random
using Test

@testset "Valid parameters and event rules" begin
    @test_throws ArgumentError transition_probabilities(1, 0, 0.0)
    @test_throws ArgumentError transition_probabilities(5, 6, 0.0)
    @test_throws ArgumentError transition_probabilities(5, 1.5, 0.0)
    @test_throws ArgumentError transition_probabilities(5, 1, -0.01)
    @test_throws ArgumentError transition_probabilities(5, 1, Inf)
    @test_throws ArgumentError transition_probabilities(5, 1, big"1e-500")
    @test_throws ArgumentError transition_probabilities(5, 1, big"1e500")
    @test_throws ArgumentError next_count(2, 0.3, 0.2, 1.0)
    example = transition_probabilities(5, 2, 0.5)
    @test isapprox(example.up, 0.3)
    @test isapprox(example.down, 0.2)
    @test isapprox(example.stay, 0.5)
    @test next_count(2, 0.3, 0.2, 0.12) == 3
    @test next_count(2, 0.3, 0.2, 0.41) == 1
    @test next_count(2, 0.3, 0.2, 0.72) == 2
    for N in [2, 5, 20], i in 0:N, s in [0.0, 1e-12, 0.01, 0.5, 1e300]
        p = transition_probabilities(N, i, s)
        @test all(isfinite, values(p))
        @test minimum(values(p)) >= -1e-14
        @test isapprox(sum(values(p)), 1.0)
    end
end

@testset "Exact probabilities and independent recurrence" begin
    for N in [2, 5, 20, 100], s in [0.0, 1e-12, 0.01, 0.1, 0.5]
        numerical = backward_probabilities(N, s)
        for i in 0:N
            exact = fixation_probability(N, i, s)
            @test 0.0 <= exact <= 1.0
            @test isapprox(exact, numerical[i + 1]; atol=1e-11, rtol=1e-10)
            if s == 0
                @test exact == i / N
            end
        end
    end
    @test isapprox(fixation_probability(5, 2, 0.5), 135 / 211)
    @test isapprox(fixation_probability(100, 1, 1e-16), 0.01)
    @test fixation_probability(100, 1, 0.1) > fixation_probability(100, 1, 0.01)
    @test fixation_probability(200, 1, 0.1) < fixation_probability(20, 1, 0.1)
end

@testset "Histories, boundaries and deterministic drift" begin
    lost = simulate_trajectory(MersenneTwister(1), 5, 0, 0.1, 10)
    fixed = simulate_trajectory(MersenneTwister(1), 5, 5, 0.1, 10)
    @test lost.counts == zeros(Int, 11)
    @test fixed.counts == fill(5, 11)
    @test lost.absorbed && lost.absorbed_at == 0
    @test simulate_fixation(MersenneTwister(1), 5, 0, 0.1) == (fixed=false, events=0)
    @test simulate_fixation(MersenneTwister(1), 5, 5, 0.1) == (fixed=true, events=0)
    path1 = simulate_trajectory(MersenneTwister(123), 20, 2, 0.1, 1000)
    path2 = simulate_trajectory(MersenneTwister(123), 20, 2, 0.1, 1000)
    @test path1 == path2
    @test all(0 .<= path1.counts .<= 20)
    @test all(abs.(diff(path1.counts)) .<= 1)
    @test deterministic_trajectory(5, 2, 0.0, 20) == fill(0.4, 21)
    @test isapprox(deterministic_trajectory(5, 2, 0.5, 1)[2], 0.42)
    @test all(diff(deterministic_trajectory(20, 2, 0.1, 1000)) .>= 0)
end

@testset "Confidence intervals and Monte Carlo sanity check" begin
    @test wilson_interval(0, 100).lower == 0.0
    @test wilson_interval(100, 100).upper == 1.0
    @test isapprox(wilson_interval(50, 100).lower, 0.4038315303659956)
    @test_throws ArgumentError wilson_interval(1, 0)
    rng = MersenneTwister(817)
    repetitions = 10000
    fixations = 0
    for repetition in 1:repetitions
        fixations += simulate_fixation(rng, 20, 1, 0.1).fixed
    end
    exact = fixation_probability(20, 1, 0.1)
    sampling_error = sqrt(exact * (1 - exact) / repetitions)
    @test abs(fixations / repetitions - exact) <= 6sampling_error + 1 / repetitions
end
