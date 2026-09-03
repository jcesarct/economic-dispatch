using Test
using DespachoEconomico

@testset "Despacho económico de tres generadores" begin
    result = solve_dispatch(
        ["G1", "G2", "G3"],
        [20.0, 10.0, 0.0],
        [100.0, 80.0, 60.0],
        [10.0, 20.0, 35.0],
        150.0;
        duration = 1.0,
    )

    @test result.status == "OPTIMAL"
    @test isapprox(result.table.dispatch_mw, [100.0, 50.0, 0.0]; atol = 1e-7)
    @test isapprox(result.total_generation_mw, 150.0; atol = 1e-7)
    @test isapprox(result.balance_residual_mw, 0.0; atol = 1e-7)
    @test isapprox(result.total_cost_usd, 2000.0; atol = 1e-7)
end
