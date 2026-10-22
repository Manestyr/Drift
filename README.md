# DRIFT · Milestone 0.1.2

Spielbarer **Godot-4.7-/GDScript-Desktop-Prototyp**: begehbares 36-m-Schiff, First Person, Pilotensitz, physikalischer Newtonscher 6DOF-Flug, Xbox-/PlayStation-Eingaben und abschaltbarer Flugcomputer. Sämtliche Geometrie entsteht aus Godot-Primitiven; keine externen Assets, Plugins oder Dienste.

## Start und erster Flug

`project.godot` in Godot **4.7 Stable** importieren, F5 im Editor drücken; alternativ `godot --path .`. Du startest auf der Brücke. Vorwärts zum türkisfarbenen Pilotensitz gehen und **F** drücken. **W** gibt sanften Vorwärts-RCS, **linke Maustaste** den stärkeren Hauptschub. Mausbewegungen fordern begrenzte Nick-/Gierdrehmomente an. Standardmäßig bremst die Rotationsstabilisierung anschließend mit RCS ab; **T** schaltet sie aus. Ohne Assist dreht das Schiff nach dem Loslassen weiter. Lineare Geschwindigkeit bleibt ohne angeforderte Bremsung erhalten.

Zum Überprüfen: W loslassen, V für Außenansicht, G für das Orientierungsgitter. Maus orbitieren lassen, Mausrad zum Zoomen. X halten, um relativ zum gewählten inertialen Bezugssystem zu bremsen. F verlässt den Sitz auch von außen. Zu Fuß führt S von der Brücke zum Korridor und Maschinenraum.

## Maus und Tastatur

| Aktion | Eingabe |
|---|---|
| Zu Fuß | WASD, Mausblick |
| Station betreten/verlassen | **F** innerhalb von 3 m |
| Pilot Nick/Gier | **Maus** (zusätzlich Pfeiltasten möglich) |
| RCS vor/zurück, seitlich | **W/S**, **A/D** |
| RCS hoch/runter | **Space/Shift** |
| Rollen | **Q/E** |
| Hauptantrieb | **linke Maustaste** halten |
| Alle relativen Geschwindigkeitskomponenten bremsen | **X** halten |
| Lokale Vorwärts-/Rückwärtskomponente bremsen | **Strg+W** halten |
| Lokale Seitwärtskomponente bremsen | **Strg+A** halten |
| Lokale Vertikalkomponente bremsen | **Strg+Space** halten |
| Lokale Rollrate bremsen | **Strg+R** halten |
| Automatische Rotationsstabilisierung an/aus | **T** |
| Aktuelle Lage halten / lösen | **H** |
| Inertialen Bremsbezug wechseln | **F7** oder Flugcomputer-Menü |
| Außenkamera / Orientierungsgitter | **V / G** |
| Außenkamera orbitieren / zoomen | Maus / Mausrad |
| Maus freigeben/einfangen | **Esc** |
| Pause und Einstellungen | **P** |
| Debug-Menü / Schiff zurücksetzen | **F3 / F5** im laufenden Spiel |

**Modifier haben Vorrang:** Während Strg gehalten wird, werden normale Tastatur-Schub-/Rotationsbefehle einschließlich Hauptantrieb und Maus-Drehmoment unterdrückt. W/A/Space/R wählen dann ausschließlich Bremsachsen. Gepufferte Mausbewegung wird verworfen. Beim Sitz-, Kamera-, Geräte- und Pausewechsel wird die virtuelle Flugmaus ebenfalls zurückgesetzt. Eine Mausbewegung dreht niemals direkt den Schiffskörper: Sie lenkt einen begrenzten virtuellen Stick, der in etwa 0,33 s zur Mitte zurückkehrt. Nur die Crew-Kamera und Außenkamera werden direkt bewegt.

## Controller

| Aktion | Xbox / PlayStation |
|---|---|
| Zu Fuß bewegen / umsehen | Linker / rechter Stick |
| Interaktion, Sitz betreten/verlassen | A / Kreuz |
| Pilot Pitch/Yaw | Linker Stick |
| Pilot seitwärts / vertikal | Rechter Stick |
| Hauptschub vorwärts, proportional | RT / R2 |
| Rückwärts-RCS, proportional | LT / L2 |
| Rollen links / rechts | LB / L1 bzw. RB / R1 |
| Außenkamera | Y / Dreieck |
| Flugcomputer, Standardlayout | D-Pad: **unten bremsen halten**, **oben Rotation stabilisieren**, **links Lage halten**, **rechts Gitter** |
| Außenkamera orbitieren / zoomen | **RS-Klick halten** + rechter Stick / Trigger |
| Pause und Einstellungen | Start / Options |
| Menü bedienen | D-Pad oder linker Stick; A/Kreuz bestätigen; B/Kreis zurück |

Die normalen Flugachsen bleiben vollständig erhalten. Nur der ausdrücklich gehaltene RS-Klick benutzt rechten Stick und Trigger zur Außenkamera-Bedienung; danach müssen diese zur Neutralstellung zurück, bevor sie wieder Schub geben. Linker Stick und Rolltasten bleiben dabei Flugsteuerung.

Im Pausemenü unter **Flight computer / Controller bindings** sind ein alternatives D-Pad-Layout (oben/unten und links/rechts vertauscht) sowie die Bremsfunktion des Controller-Bremsknopfs wählbar: Gesamtgeschwindigkeit, lokale Z-/X-/Y-Komponente oder Rollrate. Dort lassen sich auch Rotationsstabilisierung, Lagehaltung und Bezugsrahmen einstellen. Start/Options oder P setzt fort; B/Kreis beziehungsweise Esc geht zurück.

Weitere Einstellungen: radiale Stick-Deadzone **0,15** (0,05–0,40), Empfindlichkeit (0,25–2,00) und Y-Invertierung für Controller-Kamera/Pitch. Trigger haben eine separate Deadzone von 0,05; die Menünavigation eine höhere Betätigungsschwelle. Die letzte bewusste Eingabe wählt Maus/Tastatur oder Gamepad und passende HUD-Hinweise. Sub-Deadzone-Stickdrift, neutrale Trigger und kleine Mausbewegungen stehlen die Quelle nicht. Einstellungen werden beim Fortsetzen in `user://input_settings.cfg` gespeichert. Reset und Beenden sind ohne Tastatur erreichbar.

## Physik und Flugcomputer

60-Hz-Physik, m/s/kg/N. Masse **120.000 kg**; Hauptschub **2.400.000 N = 20 m/s² ≈ 2,04 g**; RCS-Translation insgesamt **240.000 N = 2 m/s²**. LT/L2 nutzt den vorhandenen Rückwärts-RCS, keinen rückwärts gerichteten Hauptantrieb. Keine Geschwindigkeitsbegrenzung und keine künstliche Linear-/Winkeldämpfung.

Das homogene 7 × 5 × 36-m-Rumpfmodell ergibt Trägheitsmomente **13.210.000 / 13.450.000 / 740.000 kg·m²**. Drehmomentgrenzen **5.284.000 / 5.380.000 / 296.000 Nm** ergeben maximal **0,4 rad/s²** um jede einzelne Hauptachse. Sie repräsentieren eigene paarweise arbeitende Rotations-RCS; Translation und Rotation haben getrennte Budgets. Ein normierter Gesamtvektor begrenzt gleichzeitige Achsenanforderungen. Physikzustände werden ausschließlich über Godots Kräfte-/Drehmoment-API integriert; nur der ausdrücklich ausgelöste Debug-Reset setzt Pose und Geschwindigkeiten.

Die vier getrennten Funktionen sind:

- **Rotationsstabilisierung:** bremst unbediente Rotationsachsen über begrenztes Gegenmoment. Standardmäßig im Spiel eingeschaltet; der eigenständige Body startet für freien Newtonschen Flug ausgeschaltet.
- **Achsenbremsung:** reduziert ausgewählte lokale relative Geschwindigkeitskomponenten. Strg+R reduziert nur die Rollrate.
- **Gesamtbremsung:** reduziert die Geschwindigkeit relativ zum ausgewählten **inertialen** Rahmen. Auswahl: unbewegte Arena oder virtueller Konvoi mit konstant −20 m/s entlang Welt-Z. Der Konvoi ist ein mathematischer Rahmen, kein sichtbares verfolgtes Objekt.
- **Lage halten:** H erfasst die aktuelle Weltorientierung. Ein sättigender Quaternion-PD-Regler führt dorthin zurück und stoppt die Winkelgeschwindigkeit. Bewusste manuelle Rotation löst die Lagehaltung, statt unbemerkt gegen das Ziel zu arbeiten.

Manueller Schub hat auf seiner Achse Vorrang, Hauptschub unterdrückt automatische Z-Bremsung. Die verbleibende RCS-Leistung steht orthogonalen Bremsachsen zur Verfügung; manuelle Leistung wird nicht zugunsten des Computers abgeschwächt. Nach Loslassen der Bremsanforderung gibt es keine automatische Geschwindigkeitsbremsung. Lagehaltung und Rotationsstabilisierung sind unabhängig abschaltbar. Pause friert die gesamte Simulation ein.

HUD: Weltgeschwindigkeitsbetrag, lokaler Geschwindigkeitsvektor, Vektor relativ zum gewählten Rahmen, Pitch-/Yaw-/Rollrate, zuletzt simulierter Hauptschub, lineare Eigenbeschleunigung/g, Assist-/Lagehalte-/Bremsstatus, verfügbare Brems-RCS-Leistung, Fortschritt und geschätzte Zeit bis **0,05 m/s** Restgeschwindigkeit. ETA gilt für freie RCS-Leistung und ändert sich bei manuellen Eingriffen, Kollisionen oder Rahmenwechsel. Ein zentriertes Vorwärtssymbol kennzeichnet die Schiffsnase (−Z).

Die parametrierbare g-Vignette bleibt erhalten. Keine Blitze, physiologische Grenzwerte oder Schadensregeln; lineare Schub-Eigenbeschleunigung schließt derzeit weder Kollisionsimpulse noch Winkelbelastung ein.

## Arena und Referenzsysteme

72 deterministisch verteilte, unterschiedlich große Low-Poly-Asteroiden mit passenden statischen Kugelkollisionen. Ein großes kollidierendes Stationswrack liegt 320 m seitlich und 650 m vor dem Start. Der gerade Startkorridor bleibt frei. Nicht kollidierende Distanzmarken alle 100 m und Richtungsbeschriftungen sowie ein zuschaltbares 100-m-Raster helfen bei Parallaxe und Orientierung. Das Raster liegt fest 60 m unter der Welt-Startposition und bleibt beim Flug zurück. Die Außenkamera orbitiert im Weltkoordinatensystem um die aktuelle Schiffsposition und zoomt zwischen 24 m und 6 km.

Der Innenraum bleibt eine separate **lokale World3D** mit vereinfachter künstlicher Schwerkraft. Lokale Crewpositionen sind unabhängig von der globalen RigidBody-Bewegung. Keine Beschleunigungs-/Corioliseffekte, kein EVA, kein Zero-G und kein Blick aus dem lokalen Innenraum in die äußere Arena. Pilot- und Außenkamera zeigen den tatsächlichen globalen Schiffskörper. Diese Grenze wird durch den Flugcomputer nicht verändert.

## Projekt und Tests

- `scenes/main.tscn`, `scripts/main.gd`: Einstieg, Geometrie, Interaktions-/Kamera-Kontexte und HUD.
- `ship_physics.gd`, `flight_command.gd`: Physikzustand und geräteunabhängiger Befehlsdatensatz.
- `flight_computer.gd`: reine Kraft-/Drehmomentregelung und Bremstelemetrie im festen Tick.
- `player_input.gd`, `pilot_input.gd`, `input_settings.gd`: lokale Adapter, Aktionen und persistente Einstellungen.
- `crew_controller.gd`, `crew_station.gd`: lokale Crewbewegung und exklusive Stationsbelegung.
- `test_arena.gd`, `exterior_orbit.gd`: statische Referenzen und unabhängige Kameradarstellung.
- `pause_menu.gd`: Controller-/Maus-/Tastatur-Menüs.
- `tests/`: bisherige drei Testsuiten plus Flugcomputer-/Manöver-/Eingabekonflikt-/Arena-Tests.

```bash
# Linux x86_64; benötigt curl, unzip und sha512sum:
./tools/bootstrap_godot.sh
GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh
```

Der Bootstrap installiert die offizielle, SHA512-geprüfte 4.7-Version außerhalb des Checkouts. Der Prüflauf importiert das Projekt, startet die Hauptszene und führt alle Suiten mit echter Godot-Physik aus. Die neue Manöversuite nutzt `--fixed-fps 60` für reproduzierbare, beschleunigt ausgeführte 60-Hz-Simulationsschritte; gemessene Zeiten sind **Simulationszeit**.

[Messwerte und Testergebnisse](docs/validation.md), [Architektur und spätere Schnittstellen](docs/architecture.md).

**Kein neuer grafischer Desktop- oder Controller-Hardwaretest für 0.1.2 wurde hier durchgeführt.** Der Nutzer hat einen erfolgreichen Desktop-Test des vorherigen Stands gemeldet. Für diese Version bitte Mausgefühl, Kamera/Zoom, Blickwechsel, Controller-Treiber, Neutralstellung und Menüs auf echter Hardware prüfen. Mehrere Controller werden noch nicht getrennten Spielern zugeordnet. Keine Waffen, Drohnen, KI, Netzwerk-, Replay- oder Missionssysteme.

Nächste empfohlene Aufgabe: Desktop-/Controller-Abnahme des neuen Fluggefühls und der visuellen Referenzen, danach gerichtete Crew-Beschleunigungseffekte und umschaltbare lokale Gravitation/Zero-G.
