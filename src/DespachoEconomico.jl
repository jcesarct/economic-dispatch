module DespachoEconomico

using CSV
using DataFrames
using HiGHS
using JuMP
using MAT

ENV["GKSwstype"] = get(ENV, "GKSwstype", "100")
using Plots

export load_csv_case, load_mat_case, solve_dispatch, save_results, run_case

"""Leer límites, costos y demanda desde dos archivos CSV."""
function load_csv_case(generator_file::AbstractString, load_file::AbstractString)
    generators = CSV.read(generator_file, DataFrame)
    load = CSV.read(load_file, DataFrame)

    required_generator_columns = [
        :generator,
        :pmin_mw,
        :pmax_mw,
        :cost_usd_per_mwh,
    ]
    required_load_columns = [:demand_mw, :duration_h]

    all(in.(required_generator_columns, Ref(propertynames(generators)))) ||
        error("Faltan columnas en el archivo de generadores.")
    all(in.(required_load_columns, Ref(propertynames(load)))) ||
        error("Faltan columnas en el archivo de demanda.")
    nrow(load) == 1 || error("Este ejemplo requiere exactamente un periodo.")

    return (
        names = String.(generators.generator),
        pmin = Float64.(generators.pmin_mw),
        pmax = Float64.(generators.pmax_mw),
        cost = Float64.(generators.cost_usd_per_mwh),
        demand = Float64(load.demand_mw[1]),
        duration = Float64(load.duration_h[1]),
    )
end

"""Leer el caso desde un archivo MAT con variables numéricas documentadas."""
function load_mat_case(input_file::AbstractString)
    data = matread(input_file)
    haskey(data, "generator_data") || error("Falta la variable generator_data.")
    haskey(data, "demand_mw") || error("Falta la variable demand_mw.")
    haskey(data, "duration_h") || error("Falta la variable duration_h.")

    generator_data = Matrix{Float64}(data["generator_data"])
    size(generator_data, 2) == 3 ||
        error("generator_data debe tener tres columnas: Pmin, Pmax y costo.")

    demand_raw = data["demand_mw"]
    duration_raw = data["duration_h"]
    demand = demand_raw isa Number ? Float64(demand_raw) : Float64(first(demand_raw))
    duration = duration_raw isa Number ? Float64(duration_raw) : Float64(first(duration_raw))
    names = ["G$(i)" for i in axes(generator_data, 1)]

    return (
        names = names,
        pmin = generator_data[:, 1],
        pmax = generator_data[:, 2],
        cost = generator_data[:, 3],
        demand = demand,
        duration = duration,
    )
end

"""Validar datos y resolver el despacho económico lineal."""
function solve_dispatch(names, pmin, pmax, cost, demand; duration = 1.0)
    n = length(names)
    n > 0 || error("Debe existir al menos un generador.")
    length(pmin) == n == length(pmax) == length(cost) ||
        error("Los vectores de generadores deben tener la misma longitud.")
    all(isfinite, vcat(pmin, pmax, cost, [demand, duration])) ||
        error("Los datos contienen valores no finitos.")
    all(pmin .>= 0.0) || error("Pmin no puede ser negativa en este ejemplo.")
    all(pmax .>= pmin) || error("Cada Pmax debe ser mayor o igual que Pmin.")
    all(cost .>= 0.0) || error("Los costos deben ser no negativos.")
    duration > 0.0 || error("La duración debe ser positiva.")
    sum(pmin) <= demand <= sum(pmax) ||
        error("La demanda está fuera de la capacidad factible del sistema.")

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, pmin[g] <= generation[g = 1:n] <= pmax[g])
    @objective(model, Min, duration * sum(cost[g] * generation[g] for g in 1:n))
    @constraint(model, power_balance, sum(generation[g] for g in 1:n) == demand)

    optimize!(model)
    status = termination_status(model)
    status == JuMP.MOI.OPTIMAL || error("El optimizador terminó con estado $status.")

    dispatch = value.(generation)
    total_generation = sum(dispatch)
    balance_residual = total_generation - demand
    total_cost = objective_value(model)

    table = DataFrame(
        generator = String.(names),
        pmin_mw = Float64.(pmin),
        pmax_mw = Float64.(pmax),
        cost_usd_per_mwh = Float64.(cost),
        dispatch_mw = dispatch,
        operating_cost_usd = duration .* Float64.(cost) .* dispatch,
    )

    return (
        table = table,
        demand_mw = Float64(demand),
        duration_h = Float64(duration),
        total_generation_mw = total_generation,
        balance_residual_mw = balance_residual,
        total_cost_usd = total_cost,
        status = string(status),
    )
end

"""Guardar resultados en CSV, MAT y PNG."""
function save_results(result, output_dir::AbstractString)
    mkpath(output_dir)
    CSV.write(joinpath(output_dir, "dispatch_results.csv"), result.table)

    summary = DataFrame(
        demand_mw = [result.demand_mw],
        duration_h = [result.duration_h],
        total_generation_mw = [result.total_generation_mw],
        balance_residual_mw = [result.balance_residual_mw],
        total_cost_usd = [result.total_cost_usd],
        solver_status = [result.status],
    )
    CSV.write(joinpath(output_dir, "summary.csv"), summary)

    matwrite(
        joinpath(output_dir, "dispatch_results.mat"),
        Dict(
            "dispatch_mw" => result.table.dispatch_mw,
            "pmin_mw" => result.table.pmin_mw,
            "pmax_mw" => result.table.pmax_mw,
            "cost_usd_per_mwh" => result.table.cost_usd_per_mwh,
            "demand_mw" => result.demand_mw,
            "duration_h" => result.duration_h,
            "total_cost_usd" => result.total_cost_usd,
            "balance_residual_mw" => result.balance_residual_mw,
        );
        compress = true,
    )

    figure = bar(
        result.table.generator,
        result.table.dispatch_mw;
        xlabel = "Generador",
        ylabel = "Potencia despachada [MW]",
        title = "Despacho económico óptimo",
        legend = false,
        color = :steelblue,
        ylim = (0, 1.15 * maximum(result.table.pmax_mw)),
        size = (850, 500),
        dpi = 150,
    )
    savefig(figure, joinpath(output_dir, "dispatch.png"))
    return nothing
end

"""Ejecutar el caso CSV o MAT desde la raíz del repositorio."""
function run_case(format::Symbol = :csv; root = normpath(joinpath(@__DIR__, "..")))
    case = if format == :csv
        load_csv_case(
            joinpath(root, "data", "input", "generators.csv"),
            joinpath(root, "data", "input", "load.csv"),
        )
    elseif format == :mat
        load_mat_case(joinpath(root, "data", "mat", "dispatch_input.mat"))
    else
        error("Formato no admitido. Use :csv o :mat.")
    end

    result = solve_dispatch(
        case.names,
        case.pmin,
        case.pmax,
        case.cost,
        case.demand;
        duration = case.duration,
    )
    save_results(result, joinpath(root, "results"))
    return result
end

end
