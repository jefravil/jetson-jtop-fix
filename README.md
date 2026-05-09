**Run the script**:
```bash
    chmod +x fix_jtop_jetpack622.sh
    
    sudo ./fix_jtop_jetpack622.sh
    
```
### En caso no Funcione prueba esto:

## Paso 1: Identificar qué versión exacta de L4T detecta tu sistema

Ejecuta este comando en tu terminal:

```bash
cat /etc/nv_tegra_release
```

O este otro:

```bash
jtop -v
```

Busca la línea que dice **L4T**. Probablemente verás algo como `36.4.0` o `36.4.3`.

Anota ese número.

---

## Paso 2: Localizar el archivo de variables de jtop

Como los scripts no lo están encontrando bien, vamos a buscar la ruta real en tu sistema:

```bash
python3 -c "import jtop, os; print(os.path.join(os.path.dirname(jtop.__file__), 'core/jetson_variables.py'))"
```
## Paso 3: Editar el archivo manualmente

Si esto te da un error, intenta quitar `/core` de la ruta:

```bash
python3 -c "import jtop, os; print(os.path.join(os.path.dirname(jtop.__file__), 'jetson_variables.py'))"
```

Una vez tengas la ruta (la llamaremos `/RUTA/AL/ARCHIVO.py`), ábrela con nano usando privilegios de superusuario:

```bash
sudo nano /RUTA/AL/ARCHIVO.py
```

Busca un bloque de texto que se parece a un diccionario llamado `JETPACK_MAP`. Se verá algo así:

```python
JETPACK_MAP = {
    "36.2.0": "6.0 DP",
    "36.3.0": "6.0 GA",
    "36.4.4": "6.2.1",
    # ... otras versiones ...
}
```

---

## Paso 4: Agregar tu versión

Añade una línea con el número de L4T que obtuviste en el Paso 1.

Por ejemplo, si tu versión es la `36.4.0`, añade la línea resaltada:

```python
"36.4.4": "6.2.1",
"36.4.0": "6.2.1",  # <-- AÑADE ESTA LÍNEA (asegúrate de poner la coma al final)
```

> Nota: Si no estás seguro de cuál poner, puedes añadir varias para cubrir todas las posibilidades del release `6.2.1`:

```python
"36.4.0": "6.2.1",
"36.4.3": "6.2.1",
```

---

## Paso 5: Guardar y Reiniciar

Presiona `Ctrl + O` y luego `Enter` para guardar.

Presiona `Ctrl + X` para salir.

Reinicia el servicio de jtop:

```bash
sudo systemctl restart jtop.service
```

Abre `jtop`.
