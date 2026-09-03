# Datos del caso de prueba

Los datos son sintéticos y se utilizan únicamente para demostrar el flujo de
trabajo. `generators.csv` contiene los límites y costos variables de tres
generadores. `load.csv` contiene una demanda de 150 MW durante una hora.

El script `scripts/create_mat_inputs.jl` transforma los CSV en
`data/mat/dispatch_input.mat`. Cuando se sustituyan estos archivos por datos
reales, debe documentarse su fuente, licencia, fecha, unidades y tratamiento.
