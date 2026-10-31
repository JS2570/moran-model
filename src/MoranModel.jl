module MoranModel

using Random
using LinearAlgebra

export validate_parameters, transition_probabilities, next_count
export simulate_trajectory, simulate_fixation, fixation_probability
export backward_probabilities, wilson_interval, deterministic_trajectory

# 1. Check that the numbers describe a valid population.
function validate_parameters(N, i, s)
    N isa Integer && N >= 2 || throw(ArgumentError("N must be an integer at least 2."))
    i isa Integer && 0 <= i <= N || throw(ArgumentError("i must be an integer from 0 to N."))
    s isa Real && isfinite(s) && s >= 0 && isfinite(Float64(s)) && (s == 0 || Float64(s) > 0) || throw(ArgumentError("s must be finite and nonnegative; a positive s must convert to a finite, positive Float64."))
    return nothing
end

# 2. Probabilities of gaining one copy, losing one copy, or staying put.
function transition_probabilities(N, i, s)
    validate_parameters(N, i, s)
    relative_fitness = 1.0 + Float64(s)
    # Dividing both reproductive weights by relative_fitness avoids overflow.
    weight_A = Float64(i)
    weight_B = (N - i) / relative_fitness
    total_weight = weight_A + weight_B
    parent_A = weight_A / total_weight
    parent_B = weight_B / total_weight
    up = parent_A * (N - i) / N
    down = parent_B * i / N
    stay = 1.0 - up - down
    return (up=up, down=down, stay=stay)
end

# 3. Turn a uniform random draw into the next allele count.
function next_count(i, up, down, u)
    0 <= u < 1 || throw(ArgumentError("u must be at least 0 and less than 1."))
    if u < up
        return i + 1
    elseif u < up + down
        return i - 1
    else
        return i
    end
end

# 4. Store one history. After absorption, repeat the same count to the horizon.
function simulate_trajectory(rng, N, i0, s, max_events)
    validate_parameters(N, i0, s)
    max_events isa Integer && max_events >= 0 || throw(ArgumentError("max_events must be a nonnegative integer."))
    counts = Vector{Int}(undef, max_events + 1)
    counts[1] = i0
    i = i0
    absorbed_at = nothing
    if i == 0 || i == N
        absorbed_at = 0
    end
    for event in 1:max_events
        if 0 < i < N
            probabilities = transition_probabilities(N, i, s)
            i = next_count(i, probabilities.up, probabilities.down, rand(rng))
            if i == 0 || i == N
                absorbed_at = event
            end
        end
        counts[event + 1] = i
    end
    return (counts=counts, absorbed=absorbed_at !== nothing, absorbed_at=absorbed_at)
end

# 5. Run until the allele is lost or fixed. There is no time cutoff.
function simulate_fixation(rng, N, i0, s)
    validate_parameters(N, i0, s)
    i = i0
    events = 0
    while 0 < i < N
        probabilities = transition_probabilities(N, i, s)
        i = next_count(i, probabilities.up, probabilities.down, rand(rng))
        events += 1
    end
    return (fixed=i == N, events=events)
end

# 6. Exact probability. log1p and expm1 preserve accuracy near neutrality.
function fixation_probability(N, i, s)
    validate_parameters(N, i, s)
    if i == 0
        return 0.0
    elseif i == N
        return 1.0
    elseif s == 0
        return i / N
    end
    log_fitness = log1p(Float64(s))
    numerator = -expm1(-i * log_fitness)
    denominator = -expm1(-N * log_fitness)
    return numerator / denominator
end

# 7. Independent check: solve the backward recurrence as linear equations.
function backward_probabilities(N, s)
    validate_parameters(N, 0, s)
    diagonal = zeros(N - 1)
    lower = zeros(N - 2)
    upper = zeros(N - 2)
    right_hand_side = zeros(N - 1)
    for i in 1:(N - 1)
        probabilities = transition_probabilities(N, i, s)
        diagonal[i] = probabilities.up + probabilities.down
        if i > 1
            lower[i - 1] = -probabilities.down
        end
        if i < N - 1
            upper[i] = -probabilities.up
        else
            right_hand_side[i] = probabilities.up
        end
    end
    matrix = Tridiagonal(lower, diagonal, upper)
    interior = matrix \ right_hand_side
    return vcat(0.0, interior, 1.0)
end

# 8. A 95% Wilson confidence interval for k successes in n repetitions.
function wilson_interval(k, n)
    n isa Integer && n > 0 || throw(ArgumentError("n must be a positive integer."))
    k isa Integer && 0 <= k <= n || throw(ArgumentError("k must be an integer from 0 to n."))
    z = 1.959963984540054
    estimate = k / n
    denominator = 1.0 + z^2 / n
    centre = (estimate + z^2 / (2n)) / denominator
    half_width = z * sqrt(estimate * (1 - estimate) / n + z^2 / (4n^2)) / denominator
    lower = max(0.0, centre - half_width)
    upper = min(1.0, centre + half_width)
    if k == 0
        lower = 0.0
    elseif k == n
        upper = 1.0
    end
    return (lower=lower, upper=upper)
end

# 9. A deterministic mean-field comparison, using one-event time steps.
function deterministic_trajectory(N, i0, s, max_events)
    validate_parameters(N, i0, s)
    max_events isa Integer && max_events >= 0 || throw(ArgumentError("max_events must be nonnegative."))
    frequencies = Vector{Float64}(undef, max_events + 1)
    x = i0 / N
    frequencies[1] = x
    for event in 1:max_events
        change = (s * x / (1.0 + s * x)) * ((1.0 - x) / N)
        x = x + change
        frequencies[event + 1] = x
    end
    return frequencies
end

end
