# Reproducción de resultados

```bash
git clone https://github.com/USUARIO/despacho-economico-julia.git
cd despacho-economico-julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. test/runtests.jl
julia --project=. scripts/run_dispatch.jl csv
```

El resultado esperado es `[100, 50, 0]` MW y 2000 USD para una hora.
