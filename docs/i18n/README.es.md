# Status

Una aplicación para Mac que vive en la barra de menús y lee el equipo en silencio. Un clic en el icono de arriba abre el procesador, la memoria, la red y la batería. El tablero muestra el cuadro completo. También se puede dejar en el escritorio como widget, en cuatro tamaños.

Las cifras se quedan en el Mac. No se envía nada a un servidor, y no hace falta una cuenta.

<p align="center">
  <a href="../../README.md"><img alt="English" src="https://img.shields.io/badge/English-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.ar.md"><img alt="Arabic" src="https://img.shields.io/badge/%D8%A7%D9%84%D8%B9%D8%B1%D8%A8%D9%8A%D8%A9-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.fr.md"><img alt="French" src="https://img.shields.io/badge/Fran%C3%A7ais-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.es.md"><img alt="Spanish" src="https://img.shields.io/badge/Espa%C3%B1ol-174F46?style=for-the-badge"></a>
  <a href="./README.de.md"><img alt="German" src="https://img.shields.io/badge/Deutsch-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
  <a href="./README.tr.md"><img alt="Turkish" src="https://img.shields.io/badge/T%C3%BCrk%C3%A7e-E7E4DC?style=for-the-badge&labelColor=E7E4DC&color=3A3A3A"></a>
</p>

## Descargar

Sin Xcode y sin terminal.

1. Descargue [Status.zip](https://github.com/0xx9/Status/releases/latest/download/Status.zip).
2. Haga doble clic en el archivo. Sale la aplicación **Status**.
3. Arrastre **Status** a **Aplicaciones**.
4. La primera vez, Control-clic en **Status**, elija **Abrir** y otra vez **Abrir**. macOS lo pide una vez porque esta copia no viene de la App Store.

Después se queda en la barra de menús. Pulse el icono.

<p align="center">
  <img src="../screenshots/dashboard-light.png" alt="El tablero de Status en apariencia clara" width="920">
</p>

## Qué se ve

El tablero no es una lista de cifras. Cada instrumento tiene una cara: un anillo, un trazo y un estado.

- **Procesador.** La parte actual, el tiempo de usuario y el de sistema, los núcleos de rendimiento y los de eficiencia, y la carga de uno, cinco y quince minutos. Si la máquina informa de los gráficos, la lectura aparece al lado.
- **Memoria.** Aplicaciones, memoria reservada, comprimida y en caché, con la presión, el intercambio y lo que sigue libre.
- **Red.** Bajada y subida en la interfaz real, con la dirección y un trazo. Las interfaces internas del sistema no cuentan.
- **Batería.** Carga o tiempo restante, ciclos, y temperatura cuando el hardware la ofrece.
- **Discos.** Lectura y escritura, y lo lleno que está cada volumen.
- **Procesos.** Lo que más pesa ahora, con búsqueda, ordenado por procesador o por memoria.
- **El equipo.** Chip, sistema, tiempo encendido y estado térmico.

Una línea encima del tablero dice qué merece atención: en calma, ocupado, bajo presión, caliente, o batería baja.

<p align="center">
  <img src="../screenshots/dashboard-dark.png" alt="El tablero de Status en apariencia oscura" width="920">
</p>

## Barra de menús

El clic izquierdo abre el panel pequeño. El clic derecho abre el menú: pausar, actualizar, detalles, ajustes y salir.

Se elige qué acompaña al icono: procesador, memoria, red o batería, hasta tres a la vez. Una sola medida dibuja un trazo pequeño en lugar de un número.

La vigilancia funciona sola. Se puede pausar, o hacerla más suave con batería y en el modo de bajo consumo. El ritmo es de un segundo, de dos, o de cinco.

Llega un aviso cuando el procesador, la memoria o el calor cruzan el límite elegido. Los primeros momentos tras el arranque se quedan en silencio.

El inicio de sesión se activa en Ajustes. Una compilación firmada en local puede pedir una autorización única en Ajustes del Sistema.

## Widgets

Cuatro tamaños: pequeño, mediano, grande y extragrande. El mismo tablero: un anillo del procesador, memoria, red, batería y un trazo de las últimas lecturas. El reloj de la cara es la hora de la última lectura. Si se mueve, las cifras son nuevas.

El widget lee el estado que escribe la aplicación, así que coincide con la barra de menús y no toma una muestra pobre por su cuenta. Si la aplicación no está en marcha, mide él mismo.

<p align="center">
  <img src="../screenshots/widget-small-light.png" alt="Widget pequeño de Status" width="220">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-medium-light.png" alt="Widget mediano de Status" width="460">
</p>

<p align="center">
  <img src="../screenshots/widget-large-light.png" alt="Widget grande de Status" width="420">
  &nbsp;&nbsp;
  <img src="../screenshots/widget-extra-light.png" alt="Widget extragrande de Status" width="640">
</p>

Después de instalar una versión nueva, quite el widget antiguo de Status del escritorio y vuelva a añadirlo. macOS ata el widget a la copia de la aplicación desde la que se añadió.

## Idioma

La aplicación sigue el idioma del sistema. En árabe, la disposición va de derecha a izquierda y las cifras se quedan en su sitio. Ajustes cambia entre árabe e inglés cuando se quiera.

Las páginas de este repositorio son distintas. Los botones de arriba abren la misma explicación en inglés, árabe, francés, alemán y turco.

## Compilación

Solo si quiere compilarlo usted. La descarga de arriba es la aplicación. macOS 15 y Xcode 16 o posterior.

```bash
git clone https://github.com/0xx9/Status.git
cd Status
xcodebuild -project Status.xcodeproj -scheme Status -destination 'platform=macOS' -configuration Release build
open ~/Library/Developer/Xcode/DerivedData/Status-*/Build/Products/Release/Status.app
```

O abra `Status.xcodeproj` y ejecútelo.

La aplicación no está en un sandbox, porque los procesos, los discos y la red lo necesitan. La extensión del widget sí lo está, y lee el archivo de estado que la aplicación escribe en el contenedor del widget.

## Dentro del proyecto

| Carpeta | Qué guarda |
| --- | --- |
| `Status` | Barra de menús, tablero, ajustes y avisos |
| `StatusWidgets` | El widget de macOS |
| `Shared` | Medición, cálculo, formato y textos |
| `StatusTests` | Cálculo, formato y una muestra real del equipo |
| `tools` | El dibujo del icono |

Versión 1.0. Identificador `com.muhsan.status`.
