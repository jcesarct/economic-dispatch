# Instalación

1. Instale Julia 1.10 o posterior y Git.
2. Clone el repositorio.
3. Entre en la carpeta del proyecto.
4. Ejecute `julia --project=. -e 'using Pkg; Pkg.instantiate()'`.
5. Ejecute las pruebas con `julia --project=. test/runtests.jl`.

Si `julia` no se reconoce como comando, cierre y vuelva a abrir Git Bash después
de instalar Julia y confirme que Julia está incluida en `PATH`.
