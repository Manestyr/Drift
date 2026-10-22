# DRIFT · Milestone 0.1.4

Spielbarer **Godot-4.7-/GDScript-Desktop-Prototyp**: begehbares 36-m-Schiff, First Person, Pilotensitz, physikalischer Newtonscher 6DOF-Flug, Xbox-/PlayStation-Eingaben, abschaltbarer Flugcomputer und drei physisch montierte Cockpitinstrumente. Sämtliche Geometrie entsteht aus Godot-Primitiven; keine externen Assets, Plugins oder Dienste.

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
| Drift Cancel (nur gehalten, X/Y) | **C** |
| Retrograde ausrichten / laufendes Manöver abbrechen | **B** |
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
| Drift Cancel / Retrograde, Standard | X / Quadrat **halten** / Back bzw. Share **drücken** |
| Flugcomputer, Standardlayout | D-Pad: **unten bremsen halten**, **oben Rotation stabilisieren**, **links Lage halten**, **rechts Gitter** |
| Außenkamera orbitieren / zoomen | **RS-Klick halten** + rechter Stick / Trigger |
| Pause und Einstellungen | Start / Options |
| Menü bedienen | D-Pad oder linker Stick; A/Kreuz bestätigen; B/Kreis zurück |

Die normalen Flugachsen bleiben vollständig erhalten. Nur der ausdrücklich gehaltene RS-Klick benutzt rechten Stick und Trigger zur Außenkamera-Bedienung; danach müssen diese zur Neutralstellung zurück, bevor sie wieder Schub geben. Linker Stick und Rolltasten bleiben dabei Flugsteuerung.

Im Pausemenü unter **Flight computer / Controller bindings** sind ein alternatives D-Pad-Layout (oben/unten und links/rechts vertauscht) sowie die Bremsfunktion des Controller-Bremsknopfs wählbar: Gesamtgeschwindigkeit, lokale Z-/X-/Y-Komponente oder Rollrate. Dort lassen sich auch Rotationsstabilisierung, Lagehaltung und Bezugsrahmen einstellen. Start/Options oder P setzt fort; B/Kreis beziehungsweise Esc geht zurück.

Zusätzlich gibt es eine **Maus-Flugempfindlichkeit** von 0,25–2,00 (Standard 1,00) im Haupt-Pausemenü; sie skaliert nur den virtuellen Flugstick, nicht den Crew-Mausblick oder die Außenkamera.

Weitere Einstellungen: radiale Stick-Deadzone **0,15** (0,05–0,40), Empfindlichkeit (0,25–2,00) und Y-Invertierung für Controller-Kamera/Pitch. Trigger haben eine separate Deadzone von 0,05; die Menünavigation eine höhere Betätigungsschwelle. Die letzte bewusste Eingabe wählt Maus/Tastatur oder Gamepad und passende HUD-Hinweise. Sub-Deadzone-Stickdrift, neutrale Trigger und kleine Mausbewegungen stehlen die Quelle nicht. Einstellungen werden beim Fortsetzen in `user://input_settings.cfg` gespeichert. Reset und Beenden sind ohne Tastatur erreichbar.

## Advanced Flight Dynamics

**Drift Cancel ist standardmäßig AUS und kein permanenter Assist.** Nur solange **C** beziehungsweise die konfigurierte Controller-Taste/Kombination gehalten wird, bremst der Flugcomputer die **lokalen X-/Y-Komponenten** der Geschwindigkeit relativ zum gewählten inertialen Referenzrahmen ab. Die lokale Z-Komponente bekommt dadurch **keine** Korrekturkraft. Eine Drehung allein aktiviert nichts; die Weltgeschwindigkeit bleibt dabei unverändert. Die lokalen Komponenten werden bei jeder Drehung pro Physiktick neu berechnet. Nach Loslassen entstehen keine weiteren Drift-Korrekturanforderungen (Reaktion im nächsten 60-Hz-Tick; zuvor integrierte Impulse bleiben natürlich erhalten).

Typisches Kurvenmanöver: in die neue Richtung drehen, **C halten**, gleichzeitig mit linker Maustaste beziehungsweise RT vorwärts beschleunigen. Manueller Schub auf einer X-/Y-Achse unterdrückt die automatische Korrektur auf genau dieser Achse. Die andere Querachse kann weiter geregelt werden, soweit RCS-Leistung verfügbar ist. C fügt nur X/Y hinzu; gleichzeitig ausdrücklich angeforderte X-/Strg-Bremsungen behalten ihre eigenen Achsen, einschließlich Z. Drift-ETA ist eine aktuelle Abschätzung bis 0,05 m/s Querdrift, kein Geschwindigkeits-Snap. Bei manueller Achsenübernahme oder fehlendem Budget erscheint keine scheinpräzise ETA.

**Retrograde (B)** richtet die Hauptschubrichtung entgegen dem tatsächlichen relativen Geschwindigkeitsvektor aus. Ausrichtung und Abbremsen der Winkelgeschwindigkeit erfolgen ausschließlich über die vorhandenen begrenzten Rotationsdüsen. **Kein automatischer Hauptschub**, auch nach Abschluss nicht: Der Pilot entscheidet selbst, wann er brennt. Erneutes B während des Manövers bricht ab. Bewusste manuelle Rotation oder Verlassen des Pilotensitzes bricht ebenfalls ab. Unter **0,5 m/s relativer Geschwindigkeit** wird das Manöver unterdrückt beziehungsweise beendet, statt aus einem undefinierten Vektor ein Ziel zu erzeugen.

Während des Manövers wird der relative Geschwindigkeitsvektor fortlaufend verfolgt. Für den mehrdeutigen Rollwinkel wird die bisherige Hochachse auf die Ebene senkrecht zur Retrograde-Richtung projiziert und von Tick zu Tick fortgeführt. Bei einem anfänglich parallelen Vektor dient eine deterministische Weltachse als Ersatz. Damit wird kein Euler-Rollwinkel willkürlich neu gesetzt. Große sprunghafte Referenzänderungen können ein neues Ziel verlangen; die physische Drehung bleibt begrenzt. Abschluss erfordert **<0,5° Lagefehler und <0,5°/s Restdrehrate für 0,5 s**. Danach hält die Lagehaltung das erreichte Ziel; sie startet bei späteren Referenzänderungen kein neues Retrograde-Manöver. Der Status meldet dann gegebenenfalls `COMPLETE / TARGET CHANGED`. Manuelle Rotation löst die Lagehaltung.

Das Cockpit zeigt **LATERAL ASSIST ON/OFF**, **DRIFT CANCEL ACTIVE**, verbleibende X/Y-Drift, Drift-ETA, Retrograde-Status sowie aktive Rotation und Translationsbremsung. Propulsion zeigt die aktuell verfügbaren negativen/positiven RCS-Achsenkräfte in **MN**; bei vollem Hauptschub beträgt die zusätzliche Vorwärts-RCS-Leistung null. Rotationsdrehmomente bleiben separat und unverändert.

Controller-Bindings lassen sich unter **Pause → Advanced flight / Controller bindings** frei auf gemappte Buttons und einen optionalen gehaltenen Modifier legen. Standard: **X/Quadrat** für Drift, kein Modifier; **Back/Share** für Retrograde. **Start/Options und Guide** bleiben als Menü-/Systemtasten reserviert. Drift und Retrograde müssen verschiedene Tasten haben; der Modifier darf nicht zugleich Retrograde auslösen. Bindings werden gespeichert. Aktive neue Bindings haben Vorrang vor überlappenden alten Funktionen; ein Modifier reserviert seine alte Funktion, während er gehalten wird. Auch Roll- und Kamera-/Bremsaktionen werden dann entsprechend konsumiert, damit ein umbelegter Knopf nicht das eigene Manöver sofort abbricht. Das Pausemenü bietet Kamerawechsel und Sitzverlassen als Controller-Fallback, falls A/Y neu belegt wurden. Profilwechsel löschen alte gehaltene Zustände, damit kein Assist hängen bleibt. Mehrere lokale Operatoren mit getrennten Geräteprofilen sind weiterhin nicht implementiert.

**Schubkonfiguration (Gameplay, kein Anspruch auf reale Technik):** Haupttriebwerk 100%, Quer-RCS 50%, Rückwärtsschub 60%. Konfigurierbar am `ShipPhysics`: `main_thrust_n`, `rcs_thrust_n` (X/Y), `forward_rcs_thrust_n` und `reverse_thrust_n`. Für gleichzeitige RCS-Achsen gilt ein richtungsabhängiges Ellipsoid: die quadratische Summe der auf ihre jeweiligen positiven/negativen Grenzkräfte normierten Komponenten überschreitet eins nicht. Manuelle Anforderungen erhalten ihr Budget zuerst; orthogonale Automatik nutzt den Rest. Vorwärts-RCS kann den Haupttriebwerks-Gesamtdeckel nicht überschreiten. Die Rotation hat ein eigenes Drehmoment-Ellipsoid. Das abstrahiert einzelne Düsen, Angriffspunkte, Treibstoff und gekoppelte Kraft-/Momentenbilanzen; ein echtes Thruster-Layout ist noch nicht implementiert.

[Drift mit Hauptschub](docs/screenshots/advanced-drift.png) · [Retrograde ohne Hauptschub](docs/screenshots/advanced-retrograde.png) · [Controller-Bindings](docs/screenshots/advanced-bindings.png)

## Cockpitinstrumente

Beim Start gibt es **keine permanente Debug-Textwand**. **F3** blendet die bisherigen technischen Daten und das Debug-Menü gemeinsam ein/aus. Außerhalb der Displays erscheint regulär nur die kontextuelle Stationsaufforderung. Drei geneigte, gerahmte Bildschirme mit Sockeln sitzen unterhalb der normalen Piloten-Sichtlinie; dieselben Texturen sind auch am lokalen Brückenpult zu sehen.

1. **Navigation:** echte 3D-Kugel mit Achsenringen und Pfeilen. **Blau = Forward (−Z), Orange = Geschwindigkeit, Grün = tatsächliche Schub-Beschleunigung.** Zahlen bleiben in m/s beziehungsweise m/s² korrekt. Bei neutralem Schub bleibt der Driftpfeil sichtbar und der grüne Pfeil verschwindet. **N** wechselt schiffslokale/Weltachsen; dieselbe Wahl ist im Flugcomputer-Pausemenü per Controller erreichbar. Die Geschwindigkeit bezieht sich in beiden Darstellungen auf den ausgewählten inertialen Flugcomputer-Rahmen; N ändert nur die Darstellung, F7 den Bezugsrahmen.
2. **Propulsion / RCS:** Hauptschub-Prozent, tatsächliche Translations- und Rotations-RCS je Achse, Beschleunigung und g. Orange zeigt zugeteilte Leistung; grüne Marken zeigen den tatsächlich zugeteilten automatischen Gegensteuerungsanteil. Die linke/rechte Balkenhälfte bedeutet negative/positive lokale Achse; **−Z = vorwärts**, +Z = rückwärts. Nullmarken bleiben mittig. Dies ist kein Schema einzelner physischer Düsen.
3. **Flight Computer:** Rotationsstabilisierung, Lagehaltung, Bremsachsen einschließlich Rollbremse, Pitch-/Yaw-/Rollrate, Referenzrahmen, Bremsfortschritt, ETA und verfügbare Brems-RCS-Leistung. ETA gilt weiter für freie RCS-Leistung bis 0,05 m/s und ist beim freien Flug als inaktiv gekennzeichnet.

Jedes Instrument rendert in einen **512×448-SubViewport**, dessen Textur auf einem **1,05×0,92-m-Quad** im 3D-Cockpit liegt. Die normale Kamera bleibt unverändert. Bei 1280×720 liegen die sichtbaren Display-Rechtecke ungefähr bei X=79–470, 470–810 und 810–1201, Y=379–694. Typische 24-Pixel-Schrift in der Textur erscheint damit etwa 16 Pixel hoch. Es gibt keine drei Canvas-HUD-Karten. Die Navigation hat eine eigene World3D mit geometrischen Pfeilen, keine Textsimulation eines 3D-Instruments.

[Gerendertes Cockpit](docs/screenshots/cockpit.png) · [Automatische Bremsung](docs/screenshots/braking.png) · [Start auf der Brücke ohne Debug-Overlay](docs/screenshots/bridge.png)

Die Bilder wurden bei 1280×720 mit Godot 4.7, Xvfb und Mesa/llvmpipe gerendert und visuell geprüft. Das ersetzt keinen interaktiven Spieltest oder echten Controller-Hardwaretest. Optional lassen sie sich auf einem vorhandenen Desktop mit `godot --path . --audio-driver Dummy --resolution 1280x720 --script res://tests/cockpit_capture.gd` reproduzieren. Dieses Diagnose-Skript setzt eine explizite Test-Startgeschwindigkeit und gibt Schub-/Bremsaktionen ein; es verändert keine Spielphysik. Die erzeugten Screenshots werden unter `docs/screenshots` gespeichert.

## Physik und Flugcomputer

60-Hz-Physik, m/s/kg/N. Masse **120.000 kg**; Hauptschub **2.400.000 N = 20 m/s² ≈ 2,04 g**; seitlicher/vertikaler RCS-Schub **1.200.000 N = 10 m/s²**, Rückwärtsschub **1.440.000 N = 12 m/s²**. Vorwärts-Manöver-RCS (W) bleibt separat mit 1.200.000 N konfiguriert; Haupttriebwerk und Vorwärts-RCS teilen eine maximale Vorwärtsleistung von 2.400.000 N. Bei vollem Hauptschub erhält Vorwärts-RCS daher keine zusätzliche Leistung. LT/L2 nutzt den vorhandenen Rückwärts-RCS, keinen rückwärts gerichteten Hauptantrieb. Keine Geschwindigkeitsbegrenzung und keine künstliche Linear-/Winkeldämpfung.

Das homogene 7 × 5 × 36-m-Rumpfmodell ergibt Trägheitsmomente **13.210.000 / 13.450.000 / 740.000 kg·m²**. Drehmomentgrenzen **5.284.000 / 5.380.000 / 296.000 Nm** ergeben maximal **0,4 rad/s²** um jede einzelne Hauptachse. Sie repräsentieren eigene paarweise arbeitende Rotations-RCS; Translation und Rotation haben getrennte Budgets. Ein normierter Gesamtvektor begrenzt gleichzeitige Achsenanforderungen. Physikzustände werden ausschließlich über Godots Kräfte-/Drehmoment-API integriert; nur der ausdrücklich ausgelöste Debug-Reset setzt Pose und Geschwindigkeiten.

Die vier getrennten Funktionen sind:

- **Rotationsstabilisierung:** bremst unbediente Rotationsachsen über begrenztes Gegenmoment. Standardmäßig im Spiel eingeschaltet; der eigenständige Body startet für freien Newtonschen Flug ausgeschaltet.
- **Achsenbremsung:** reduziert ausgewählte lokale relative Geschwindigkeitskomponenten. Strg+R reduziert nur die Rollrate.
- **Gesamtbremsung:** reduziert die Geschwindigkeit relativ zum ausgewählten **inertialen** Rahmen. Auswahl: unbewegte Arena oder virtueller Konvoi mit konstant −20 m/s entlang Welt-Z. Der Konvoi ist ein mathematischer Rahmen, kein sichtbares verfolgtes Objekt.
- **Lage halten:** H erfasst die aktuelle Weltorientierung. Ein sättigender Quaternion-PD-Regler führt dorthin zurück und stoppt die Winkelgeschwindigkeit. Bewusste manuelle Rotation löst die Lagehaltung, statt unbemerkt gegen das Ziel zu arbeiten.

Manueller Schub hat auf seiner Achse Vorrang, Hauptschub unterdrückt automatische Z-Bremsung. Die verbleibende RCS-Leistung steht orthogonalen Bremsachsen zur Verfügung; manuelle Leistung wird nicht zugunsten des Computers abgeschwächt. Nach Loslassen der Bremsanforderung gibt es keine automatische Geschwindigkeitsbremsung. Lagehaltung und Rotationsstabilisierung sind unabhängig abschaltbar. Pause friert die gesamte Simulation ein.

Die per F3 zuschaltbare Debuganzeige enthält weiterhin: Weltgeschwindigkeitsbetrag, lokaler Geschwindigkeitsvektor, Vektor relativ zum gewählten Rahmen, Pitch-/Yaw-/Rollrate, zuletzt simulierter Hauptschub, lineare Eigenbeschleunigung/g, Assist-/Lagehalte-/Bremsstatus, verfügbare Brems-RCS-Leistung, Fortschritt und geschätzte Zeit bis **0,05 m/s** Restgeschwindigkeit. ETA gilt für freie RCS-Leistung und ändert sich bei manuellen Eingriffen, Kollisionen oder Rahmenwechsel. Die Vorwärtsrichtung (−Z) erscheint jetzt als blauer Pfeil im Navigationsinstrument.

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
- `scripts/instruments/`: typisiertes `ShipTelemetry`-Snapshot, gemeinsame Display-Zeichenbasis, drei getrennte Instrumente und wiederverwendbare Cockpit-Montage.
- `tests/`: fünf bestehende Suiten plus Advanced-Flight-/Manöver-/Binding-Tests; **228 Prüfungen** insgesamt.

```bash
# Linux x86_64; benötigt curl, unzip und sha512sum:
./tools/bootstrap_godot.sh
GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh
```

Der Bootstrap installiert die offizielle, SHA512-geprüfte 4.7-Version außerhalb des Checkouts. Der Prüflauf importiert das Projekt, startet die Hauptszene und führt alle Suiten mit echter Godot-Physik aus. Die neue Manöversuite nutzt `--fixed-fps 60` für reproduzierbare, beschleunigt ausgeführte 60-Hz-Simulationsschritte; gemessene Zeiten sind **Simulationszeit**.

[Messwerte und Testergebnisse](docs/validation.md), [Architektur und spätere Schnittstellen](docs/architecture.md).

**Kein interaktiver Desktop- oder Controller-Hardwaretest für 0.1.4 wurde hier durchgeführt.** Virtuelle Render-Screenshots wurden geprüft; der Nutzer hat zuvor einen erfolgreichen Desktop-Test von 0.1.2 gemeldet. Für diese Version bitte C-Halten/Loslassen, Rückwärtsschub, Retrograde-Abbruch, Instrumente und umbelegte Controller-Kombinationen auf echter Hardware prüfen. Mehrere Controller werden noch nicht getrennten Spielern zugeordnet. Keine Waffen, Drohnen, KI, Netzwerk-, Replay- oder Missionssysteme.

Nächste empfohlene Aufgabe: Desktop-/Controller-Abnahme der Cockpit-Lesbarkeit bei unterschiedlicher Auflösung und Drift, danach gerichtete Crew-Beschleunigungseffekte und umschaltbare lokale Gravitation/Zero-G.
