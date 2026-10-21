# DRIFT · Milestone 0.1.1

Spielbarer Desktop-Prototyp mit Gamepad-Unterstützung für **Godot 4.7 Stable / GDScript**, ohne externe Assets, Plugins oder Dienste. Projekt in Godot über `project.godot` importieren und **F5 (Projekt starten)** verwenden; alternativ `godot --path .`. Im laufenden Spiel setzt F5 das Schiff zurück.

## Erster Flug

Du startest auf der Brücke eines 36 m langen Schiffs. Mit WASD und Maus umsehen/laufen. Vor dir befindet sich der türkisfarbene Pilotensitz: annähern, **E**, dann **Shift** halten für Hauptschub. Loslassen: das Schiff fliegt mit unveränderter Geschwindigkeit weiter. Mit Pfeiltasten drehen; die Weltgeschwindigkeit dreht sich dabei nicht mit. **V** zeigt das Schiff und die statischen Raummarker von außen. **E** verlässt den Sitz auch aus der Außenansicht. Zurück im Innenraum mit S Richtung Korridor und Maschinenraum laufen.

| Kontext | Steuerung |
|---|---|
| Zu Fuß | WASD, Mausblick |
| Sitz | E innerhalb von 3 m betreten; E verlassen |
| Pilot: RCS Translation | W/S vor/zurück, A/D seitlich, Space/Ctrl hoch/runter |
| Pilot: Hauptantrieb | Shift halten |
| Pilot: Rotation | Pfeile: Nick/Gier, Q/R: Roll |
| Ansicht | V Außenkamera an/aus; auch zu Fuß nutzbar |
| Maus | Esc freigeben/einfangen; freigegeben stoppt die Schubeingabe |
| Debug | F3 Menü, F5 Position und beide Geschwindigkeiten zurücksetzen |

Die Außenansicht behält bei besetztem Sitz die Flugsteuerung. Es gibt weder Geschwindigkeitsbegrenzung noch automatische Linear- oder Winkeldämpfung. Gegensteuern ist nötig! F5 verändert nicht die lokale Crewposition; die Raumreferenzobjekte bleiben statisch.

## Controller (Xbox / PlayStation)

Ein von Godot erkanntes Xbox- oder PlayStation-kompatibles Gamepad genügt. Maus/Tastatur bleiben nutzbar; die letzte bewusste Eingabe wählt die Quelle und schaltet die HUD-Hinweise um. Sticks unter der Deadzone und kleine Mausbewegungen wechseln die Quelle nicht. Es werden keine Kamerakräfte oder Flugimpulse beim Gerätewechsel erzeugt.

| Kontext | Controller |
|---|---|
| Zu Fuß bewegen / umsehen | Linker / rechter Stick |
| Interaktion, Sitz betreten/verlassen | A / Kreuz |
| Pilot Pitch und Yaw | Linker Stick: hoch/runter = Pitch, links/rechts = Yaw |
| Pilot seitwärts / vertikal | Rechter Stick: rechts/links bzw. hoch/runter |
| Hauptschub vorwärts, proportional | RT / R2 |
| Gegenschub rückwärts, proportional | LT / L2 (**vorhandener RCS**, maximal 240.000 N) |
| Roll links / rechts | LB / L1 bzw. RB / R1 |
| Außenkamera an/aus | Y / Dreieck |
| Pause und Einstellungen | Start / Options; Tastatur: P |
| Menü bedienen | D-Pad oder linker Stick: Navigation; links/rechts: Regler; A/Kreuz: bestätigen |
| Menü schließen | Start/Options, B/Kreis, P oder Escape |

Das Menü enthält Fortsetzen, Stick-Deadzone (0,05–0,40, Standard **0,15 radial**), Stick-Empfindlichkeit (0,25–2,00), Y-Invertierung, Schiffsreset und Beenden. Änderungen gelten sofort und werden beim Fortsetzen unter `user://input_settings.cfg` gespeichert. Empfindlichkeit betrifft Umsehen und Pitch/Yaw; Y-Invertierung betrifft Controller-Kamera und Pitch, nicht Translation oder Maus. Trigger haben eine separate Deadzone von 0,05. Teilweiser Stick-/Triggerausschlag bleibt proportional; diagonale RCS- und Rotationskommandos überschreiten nicht den bestehenden Gesamtwert.

Pause hält **die gesamte Simulation** an. Neutrale Sticks/Trigger erzeugen keine neue Kraft und kein Drehmoment; außerhalb der Pause bleibt vorhandene lineare und rotatorische Trägheit erhalten. Die Außenkamera sperrt Laufen/Umsehen zu Fuß, behält aber bei besetztem Sitz die Flugsteuerung. Reset ist im Pausemenü vollständig ohne Tastatur erreichbar. Mehrere gleichzeitig bediente Controller werden noch nicht getrennten Spielern zugeordnet.

**Hardwaretest offen:** Hier war kein echter Controller und kein grafischer Desktop verfügbar. Die automatisierten Tests injizieren Godot-Controllerereignisse; sie ersetzen keinen USB-/Bluetooth-, Treiber- oder Ergonomietest. Auf echter Hardware zuerst Neutralstellung, beide Trigger einzeln, alle sechs Flugachsen, Gerätewechsel sowie D-Pad/Bestätigung im Pausemenü prüfen. Bei unbekannten Geräten kann eine SDL-Controllerzuordnung erforderlich sein.

## Simulation und Anzeigen

60 Hz fester Physiktick, Meter/Sekunden/Kilogramm/Newton. 120.000 kg Masse, 2.400.000 N Hauptschub = **20 m/s² ≈ 2,04 g**; RCS 240.000 N, maximales RCS-Drehmoment 1.800.000 Nm. Translation und Rotation sind jeweils auf einen normierten Gesamtvektor begrenzt, nicht die Geschwindigkeit. Hauptantrieb und RCS addieren sich. Kräfte und Drehmomente werden körperlokal angefordert und in Weltachsen an Godots `PhysicsDirectBodyState3D` übergeben. Der RigidBody integriert Bewegung; nur der explizite Debug-Reset setzt seine Transformation.

HUD: Betrag der Weltgeschwindigkeit, Geschwindigkeit in lokalen Schiffsachsen (+X rechts, +Y oben, −Z vorwärts), tatsächlich zuletzt simulierter Hauptschub, Eigenbeschleunigung, g und geglättete anhaltende g-Last. Das Vignettenmaximum ist eine **Darstellungsbegrenzung**, keine physiologische g-Grenze. `g_effect_gain` und `g_effect_response_seconds` sind im Main-Inspector parametrierbar. Keine Blitze, kein Bewusstseins-/Schadensmodell. `ShipPhysics.acceleration_local` hält die Richtung für spätere Physiologie bereit.

## Aufbau

- `scenes/main.tscn`: startbare Hauptszene; Aufbau aus Godot-Primitiven zur Laufzeit.
- `scripts/main.gd`: Szenenaufbau, Kameras, UI, Interaktionsrouting und Komposition.
- `scripts/ship_physics.gd`: unabhängiger RigidBody, Kräfte, Telemetrie, Tick und Reset.
- `scripts/flight_command.gd`: kleiner lokaler Befehlsdatensatz ohne Input-Abhängigkeit.
- `scripts/pilot_input.gd`: Flug-Eingabeadapter mit Keyboard-Fallback.
- `scripts/player_input.gd`: lokale Eingabequelle, radiale Deadzone, Gerätewechsel und kontextabhängige Controller-Kommandos.
- `scripts/input_settings.gd`: persistente Controller-Einstellungen.
- `scripts/pause_menu.gd`: per Controller/Maus/Tastatur bedienbare Pause und Einstellungen.
- `scripts/crew_controller.gd`: lokale First-Person-Bewegung mit künstlicher Schwerkraft.
- `scripts/crew_station.gd`: Belegung und Signale einer modularen Station.
- `tests/`: echte Physik- und Szenenablauftests ohne Testframework.
- `docs/architecture.md`: Referenzsysteme und geplante Schnittstellen.
- `tools/check.sh`: Import, Start und alle drei Tests; bricht bei Fehlern ab.

Die Input Map steht in `project.godot` und kann im Editor angepasst werden. Keine Autoloads oder globalen Game-State-Singletons.

## Prüfen

```bash
GODOT_BIN=/pfad/zu/godot-4.7 ./tools/check.sh
```

Auf Linux x86_64 installiert `./tools/bootstrap_godot.sh` die offizielle, per SHA512 geprüfte Version außerhalb des Checkouts nach `/workspace/tools/godot-4.7`. Benötigt werden `curl`, `unzip` und `sha512sum`.

Mit Godot **4.7.stable.official.5b4e0cb0f** ausgeführt: Headless-Import und 120-Frame-Start sowie die bisherigen 7 Flugphysikprüfungen, 10 Ablaufprüfungen und 63 zusätzliche Controller-Prüfungen (**80 bestanden insgesamt**). Den aktuellen verbindlichen Ergebnisstand enthält `docs/validation.md`. Die Tests verwenden Godots echte Physikframes, keine selbst geschriebene Ersatzintegration. Das Szenenskript prüft Laufen, Kollisionen, Stationswechsel, Eingabe, Kameras und Trägheit nach dem Verlassen. Ein grafischer Desktop-Spieltest ist zusätzlich empfohlen.

## Bekannte Einschränkungen

- Der Innenraum liegt bewusst in einer **separaten lokalen World3D** mit künstlicher Schwerkraft. Die Crew wird nicht global mitbewegt; ihre lokale Pose ist der Zustand. Globale Position kann über `ship.global_transform * crew.position` abgeleitet werden. Keine Beschleunigungs-/Corioliswirkung, kein Zero-G, EVA oder Blick aus dem lokalen Innenraum in die äußere Welt. Pilot- und Außenkamera zeigen dagegen den tatsächlich fliegenden globalen Schiffskörper.
- Brücke, offener Korridor und Maschinenraum sind einfache kollidierende Boxen. Keine Türen, Animationen, beweglichen Scheiben oder detailreichen Assets. Pilotensicht hat nur eine Cockpit-Unterkante.
- G-Anzeige berücksichtigt bisher angeforderten Antrieb, keine Kollisionsimpulse oder Belastung durch Winkelbeschleunigung. Geglättete Last ist nur visuelle Rückmeldung.
- Außenkamera folgt dem Schiff ohne freie Orbitsteuerung. Referenzmarker stehen alle 100 m bis 1 km; weitere Raummarker sind deterministisch verteilte sichtbare Boxen ohne Kollision.
- Keine Netzwerk-/Replay-Implementierung, keine Determinismusgarantie über Physikbackends. Kein Flight Assist, Audio, Kampf, KI oder Export-Build.

## Empfohlene Reihenfolge

1. **0.2:** Referenzrahmen-Abstraktion für Crew, gerichtete Beschleunigungseffekte und umschaltbare künstliche Gravitation/Zero-G; Tests für Übergänge.
2. **0.3:** Weitere Stationsadapter und Sensorprototyp, dann ein einzelnes kurzes Kampfexperiment.
3. **0.4:** Autoritativer Host und 1–3 LAN-Spieler mit synchronisierten Kommandos/Zuständen.
4. Erst danach KI für freie Stationen, Raketen/Drohnen, Damage und Ereignisaufzeichnung/Replays; später Hangar, Missionen und Kampagne.
