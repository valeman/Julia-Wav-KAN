module UTILS

export loss_fcn, UnitGaussianNormaliser, unit_encode, unit_decode, MinMaxNormaliser, minmax_encode, minmax_decode, log_loss, node_mul_1D, node_mul_2D

using Statistics
using Flux
using CUDA, KernelAbstractions, Tullio

p = parse(Float32, get(ENV, "p", "2.0"))

function loss_fcn(m, x, y)
    return sum(abs.(m(x, y) .- y).^p)
end

eps = Float32(1e-5)

### Normaliser for zero mean and unit variance ###
struct UnitGaussianNormaliser{T<:AbstractFloat}
    μ::T
    σ::T
    ε::T
end

# Normalise to zero mean and unit variance
function unit_encode(normaliser::UnitGaussianNormaliser, x::AbstractArray)
    return (x .- normaliser.μ) ./ (normaliser.σ .+ normaliser.ε)
end

# Denormalise
function unit_decode(normaliser::UnitGaussianNormaliser, x::AbstractArray)
    return x .* (normaliser.σ .+ normaliser.ε) .+ normaliser.μ
end

# Constructor, characterises the distribution of the data, takes 3D array
function UnitGaussianNormaliser(x::AbstractArray)
    data_mean = Statistics.mean(x)
    data_std = Statistics.std(x)
    return UnitGaussianNormaliser(data_mean, data_std, eps)
end

struct MinMaxNormaliser{T<:AbstractFloat}
    min::T
    max::T
end

function minmax_encode(normaliser::MinMaxNormaliser, x::AbstractArray)
    return (x .- normaliser.min) ./ (normaliser.max - normaliser.min)
end

function minmax_decode(normaliser::MinMaxNormaliser, x::AbstractArray)
    return x .* (normaliser.max - normaliser.min) .+ normaliser.min
end

function MinMaxNormaliser(x::AbstractArray)
    data_min = minimum(x)
    data_max = maximum(x)
    return MinMaxNormaliser(data_min, data_max)
end

# Log the loss to CSV
function log_loss(epoch, train_loss, test_loss, model_name)
    open("logs/$model_name.csv", "a") do file
        write(file, "$epoch,$train_loss,$test_loss\n")
    end
end

function node_mul_1D(y, w)
    @tullio out[o, b] := w[i, o] * y[i, o, b]
end

function node_mul_2D(y, w)
    @tullio out[o, l, b] := w[i, o] * y[i, o, l, b]
end

end