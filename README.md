# Parry Survivor — prototipo

Survivor-like donde **no hay auto-ataque**: tu única ofensiva es un **parry en
pulso radial**. Pulsas un botón, se abre una ventana corta, y todo enemigo
dentro de un radio que esté en su animación de ataque recibe el golpe. No
apuntas a nadie: o están telegrafiando dentro del radio, o no pasa nada.

El prototipo existe para responder **una sola pregunta**: ¿se siente bien el
parry? Todo lo demás está al mínimo a propósito.

Godot **4.7** · resolución 1280x720 · sin sprites: todo son formas geométricas.

---

## Cómo jugarlo

**Desde el binario** (no necesita Godot):

```bash
open build/ParrySurvivor.app
```

Si no existe, genéralo con `./build.sh` (necesita las export templates de 4.7).
La primera vez macOS puede quejarse porque está firmado ad-hoc: click derecho →
*Abrir*.

**Desde el código:**

```bash
./run.sh
```

## Repartirlo a otra gente

`./build.sh` genera los tres builds y los empaqueta en `build/dist/`:

| Archivo | Tamaño | Notas |
|---|---|---|
| `ParrySurvivor-0.1.0-Windows.zip` | 36 MB | `.exe` único, x86_64 |
| `ParrySurvivor-0.1.0-Linux.tar.gz` | 27 MB | x86_64, `tar` para conservar el bit de ejecución |
| `ParrySurvivor-0.1.0-macOS.zip` | 58 MB | universal (Apple Silicon + Intel) |

Cada paquete lleva dentro un `LEEME.txt` con controles y **cómo saltarse el aviso
del sistema**, porque los tres builds van sin firmar y los tres sistemas
protestan:

- **Windows** — SmartScreen: *Más información* → *Ejecutar de todas formas*.
- **macOS** — Gatekeeper puede decir que la app está "dañada". No lo está, es la
  cuarentena de descarga: `xattr -dr com.apple.quarantine ParrySurvivor.app`.
- **Linux** — `chmod +x` y listo.

`build/` está en `.gitignore`: son ~120 MB, no van al repo. Súbelos a Drive, o
crea una release en GitHub y adjúntalos ahí.

## Controles

| Tecla | Acción |
|---|---|
| `WASD` / flechas | Mover (8 direcciones, velocidad constante) |
| `Espacio` o **click izquierdo** | Parry |
| `E` | Generar 3 enemigos (debug) |
| `R` | Reiniciar la partida |
| `Esc` | Salir |

El parry está mapeado a las dos entradas a propósito, para que compares cuál se
siente mejor sin tocar código.

---

## Cómo leer la pantalla

**La forma te dice la contra-jugada**, antes que el color:

| Silueta | Tipo | Qué hacer |
|---|---|---|
| ● Círculo sólido rojo | **Fodder** — 1 parry | Parriar cuando se ponga amarillo |
| ● Círculo grande morado | **Resistente** — 3 golpes, telegraph largo | Parriar 3 telegraphs distintos |
| ▲ Triángulo cian | **Esquivable** — nunca parriable | Solo moverse. Máximo 5 a la vez |
| ◎ Anillo rosa | **Tirador** — dispara desde 340 px | Esquivar el proyectil, o acercarte y parriarlo antes de que dispare |

**El amarillo siempre significa "parry ahora"**, en todos los tipos parriables.
El anillo que se cierra sobre el enemigo es el tiempo que te queda: cuando toca
el cuerpo, el golpe sale.

Alrededor de ti, el aro verde es el **cooldown** del parry rellenándose. El
anillo grande al pulsar es el **radio real** del pulso: verde si conectó, gris
si fallaste — así sabes si el error fue de timing o de posición.

---

## Qué me interesa que mires

En orden de importancia:

1. **¿Engancha el pulso radial?** Es la apuesta central. La alternativa era un
   parry dirigido uno-a-uno; cambiar a eso sería alcance, no arquitectura.
2. **¿El telegraph avisa lo suficiente?** 0.8s en el fodder. Si te sobra tiempo,
   el juego es demasiado permisivo; si no llegas nunca, es injusto.
3. **¿Alguna mejora se siente obviamente mejor que las otras?** Si siempre eliges
   radio, el pulso base es corto. Si siempre eliges cooldown, está muy castigado.
4. **¿El minuto 1:05 y el 1:30 cambian algo?** Ahí entran tirador y triángulos.
   Si no notas el cambio de ritmo, hay que subirles peso.
5. **¿El hit-stop se siente como peso o como tirón?**

El HUD de debug (arriba a la izquierda) muestra en vivo tu **% de acierto de
pulsos**. Si acabas una partida con 95%, el parry es demasiado fácil.

---

## Qué tocar para ajustar

Todo son `@export`: se cambian desde el inspector de Godot sin recompilar.

| Quiero cambiar… | Dónde |
|---|---|
| Ventana, radio, cooldown, daño, i-frames | Nodo `Player` en `scenes/main.tscn` |
| Vida del jugador | `Player` → `max_health` |
| Aviso del telegraph, velocidad, rango, golpes | El `.tres` del tipo en `resources/` |
| Cuándo aparece cada tipo y con qué peso | El mismo `.tres`, grupo *Spawning* |
| Ritmo de las oleadas | Nodo `Spawner` → `base_interval`, `min_interval`, `ramp_seconds` |
| Fuerza del hit-stop y del shake | Nodo `Main` → grupo *Juice* |
| Tamaño de la arena | Nodo `Arena` → `size` |

Añadir un tipo de enemigo nuevo es **un `.tres` más**, no una escena nueva: hay
una sola `enemy.tscn` para todos.

---

## Estructura

```
scenes/     main, player, enemy, projectile, floating_text
scripts/    un script por sistema; todo con tipado estático
resources/  un .tres por tipo de enemigo (stats + calendario de aparición)
```

Piezas que conviene conocer antes de tocar nada:

- `enemy.gd` — la máquina de estados `Idle → Telegraph → Attack → Recovery`.
  Solo `Telegraph` es parriable.
- `player.gd` — el pulso de parry. El `Area2D` monitoriza **siempre**; el pulso
  es lógico. Encenderla al pulsar costaría un frame de latencia.
- `upgrades.gd` — el pool de mejoras, con sus topes.
- `sfx.gd` — **audio placeholder sintetizado en runtime**. No hay ni un asset de
  sonido; hay que sustituirlo antes de enseñárselo a nadie.

## Fuera de alcance (a propósito)

Sin exportación a Steam/itch, sin arte final, sin menú principal, sin guardado.
El roster tiene 4 tipos (uno más de los 3 previstos: el tirador se añadió para
que la mejora de radio significara algo).

Las ideas aparcadas para después del prototipo están en [BACKLOG.md](BACKLOG.md).
