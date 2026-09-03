# Cómo contribuir

1. Abra un *issue* y describa el cambio o error.
2. Cree una rama: `git switch -c tipo/descripcion-corta`.
3. Realice cambios pequeños y ejecute `julia --project=. test/runtests.jl`.
4. Confirme los cambios con un mensaje claro.
5. Envíe la rama a GitHub y abra un *pull request* hacia `main`.

No incluya credenciales, datos confidenciales ni archivos grandes. Los cambios
que alteren resultados deben explicar los datos, parámetros y pruebas usados.
