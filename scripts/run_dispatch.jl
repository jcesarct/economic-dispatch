using Pkg
Pkg.activate(normpath(joinpath(@__DIR__, "..")))
Pkg.instantiate()

using DespachoEconomico

format = isempty(ARGS) ? :csv : Symbol(lowercase(ARGS[1]))
root = normpath(joinpath(@__DIR__, ".."))
result = run_case(format; root = root)

println("Estado del optimizador: ", result.status)
println("Demanda [MW]: ", result.demand_mw)
println("Generación total [MW]: ", result.total_generation_mw)
println("Residuo de balance [MW]: ", result.balance_residual_mw)
println("Costo total [USD]: ", result.total_cost_usd)
println(result.table)
