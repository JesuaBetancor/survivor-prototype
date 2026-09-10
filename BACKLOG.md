# Backlog

Ideas parked during development, to revisit **after** the phased prototype is
finished. Nothing here is scheduled.

## Dificultad estructural más allá de esquivar

Observación tras jugar la Fase 5: la dificultad real la traen los **triángulos
no-parriables**, porque obligan a moverse y a prestar atención. El resto de la
presión es de volumen, no de decisión.

Los enemigos ya se bloquean entre sí (capa 2 / máscara 2), y eso crea
formaciones interesantes, pero **no está claro que genere dificultad real**: el
jugador los atraviesa (máscara 0), así que la masa nunca lo acorrala.

Cosas que explorar cuando toque:

- Que la masa de enemigos **empuje o frene** al jugador, para que el volumen se
  convierta en una amenaza posicional y no solo visual.
- Enemigos que **cortan líneas de escape** en vez de perseguir en línea recta.
- Telegraphs **solapados a propósito**: varios enemigos sincronizando la ventana
  para forzar a elegir a quién parriar.
- Subir peso o velocidad de los triángulos si siguen siendo la única fuente real
  de tensión.

## Parry en combo

Descartado para el MVP en la Fase 2: hoy un parry no letal manda al enemigo a
`Recovery`, así que matar un resistente cuesta 2-3 ciclos de telegraph. La
alternativa —que el parry no interrumpa y se puedan encadenar varios dentro de
una misma ventana— quedó apuntada como posible mejora post-prototipo.

## Contramedidas para el tipo no-parriable

Hoy el `Esquivable` es inmortal y se controla con un tope de 5 vivos a la vez.
Alternativas si el tope se siente artificial:

- Que expiren solos pasados N segundos.
- Que sí sean matables, pero solo durante `Recovery` (otra ventana, otro timing).

## Audio de verdad

Todo el sonido actual está **sintetizado en runtime** en `scripts/sfx.gd`: tonos
cortos con decaimiento, sin ningún asset. Sirven para saber si un parry conectó,
y para nada más. Antes de que esto lo juegue alguien que no seas tú, hay que
sustituirlos por muestras reales — el sistema de reproducción (pool de 8 voces,
`play(id, variación_de_tono)`) no cambia, solo de dónde salen los `AudioStream`.
