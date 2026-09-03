using Pkg
Pkg.activate(normpath(joinpath(@__DIR__, "..")))
Pkg.instantiate()

using CSV
using DataFrames
using MAT

root = normpath(joinpath(@__DIR__, ".."))
generators = CSV.read(joinpath(root, "data", "input", "generators.csv"), DataFrame)
load = CSV.read(joinpath(root, "data", "input", "load.csv"), DataFrame)

generator_data = Matrix{Float64}(
    generators[:, [:pmin_mw, :pmax_mw, :cost_usd_per_mwh]],
)

output_dir = joinpath(root, "data", "mat")
mkpath(output_dir)
matwrite(
    joinpath(output_dir, "dispatch_input.mat"),
    Dict(
        "generator_data" => generator_data,
        "demand_mw" => Float64(load.demand_mw[1]),
        "duration_h" => Float64(load.duration_h[1]),
    );
    compress = true,
)

println("Archivo MAT creado en data/mat/dispatch_input.mat")
