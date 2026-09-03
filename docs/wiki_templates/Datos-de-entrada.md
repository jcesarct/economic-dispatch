# Datos de entrada

## Generadores

`data/input/generators.csv` contiene identificador, Pmin, Pmax y costo variable.
Las potencias están en MW y el costo en USD/MWh.

## Demanda

`data/input/load.csv` contiene una demanda de 150 MW y una duración de 1 h.

## Formato MAT

`generator_data` tiene una fila por generador y tres columnas: Pmin, Pmax y
costo. `demand_mw` y `duration_h` son escalares.
