# Milestone 0.3.4 — Shared Tactical HUD & Crew Target Designation

Basis: `22ae8f0`, `feature/milestone-0.3.3-tactical-combat`. Godot **4.7.stable.official.5b4e0cb0f**, GDScript, unveränderte 60-Hz-Flug-/Kampfphysik. Neuer Branch: `feature/milestone-0.3.4-shared-tactical-hud`.

## Ausprobieren

Kontakt Alpha im Missionsmenü starten, vorzugsweise MANUAL / NORMAL, Seed 71. Auf der Brücke die linke Sensor-/Drohnenstation mit **✕** betreten. **L2 halten + R3 drücken** öffnet DESIGNATE. ALPHA mit **Steuerkreuz links/rechts** auswählen und mit **Quadrat** als Pilotenziel markieren. Mit **✕** die Station verlassen, zum Pilotensitz gehen und dort **✕** drücken. Die orange Raute und der beschriftete Richtungsvektor stammen aus derselben schiffsweiten Designation. **Dreieck** zeigt sie auch in der orbitierbaren Außenkamera.

Bei beobachteten anfliegenden Raketen erscheinen zusätzlich rote Warnmarker. Der Sensoroperator kann eine Rakete auswählen und mit **R1** priorisieren. Diese erscheint mit PRIORITY und einem zusätzlichen Ring vor automatischen Warnungen. In MANUAL entstehen dadurch weder Raketenstarts noch Drohnenaufträge.

## Vollständige neue Kontextbelegung

| Funktion | PlayStation | Xbox | Tastatur |
|---|---|---|---|
| DESIGNATE öffnen, an Sensor-/Drohnenkonsole | L2 halten + R3 drücken | LT halten + RS drücken | Z |
| Kontakt auswählen | Steuerkreuz ←/→ | D-pad ←/→ | Pfeile ←/→ |
| Ausgewähltes feindliches Schiff als Pilotenziel | Quadrat | X | T |
| Ausgewählte feindliche Rakete priorisieren | R1 | RB | R |
| Designation des ausgewählten Kontakts entfernen | R3 | RS drücken | O |
| Zur normalen Drohnenbedienung | Kreis | B | Esc oder Z |
| Station verlassen | ✕ | A | F |
| Außenkamera, DESIGNATE dabei schließen | Dreieck | Y | V |
| Pause/Einstellungen | Options | Start | P |

**R3 allein behält außerhalb DESIGNATE die bisherige Rollenfreigabe.** L2 besitzt an dieser Konsole bisher keinen Drohnenauftrag; der sichtbare neue Akkord überschreibt somit keinen vorhandenen Einzelbefehl. L2 muss bereits gehalten sein, bevor R3 gedrückt wird. R1, Quadrat und R3 führen in DESIGNATE ausschließlich die angezeigten Markierungsaktionen aus. Steuerkreuz oben/unten startet oder positioniert dort keine Drohne. Kreis schließt den Kontext, ohne den Sicherheitsgurt zu lösen. Pause und Stationswechsel behalten die bestehenden Neutral-/Release-Sperren.

Die normale Drohnenkonsole bleibt vollständig bedienbar: Steuerkreuz oben starten, unten Wegpunkt, R1 DEFEND an/aus, L1 HOLD, Share/Create RECALL, Quadrat Tracking, Steuerkreuz ←/→ Kontaktwahl, R3 Rollenfreigabe. Waffen-, Raketen-, Karten- und Pilotenbelegungen aus [0.3.3](tactical-0.3.3.md) bleiben erhalten. Die laufende Anzeige verwendet das aktive PS-/Xbox-/Tastaturschema.

## Was die Anzeigen bedeuten

- **Orange Raute / TARGET:** ausdrücklich markiertes feindliches Schiff, geschätzte Entfernung, Betrag der relativen Geschwindigkeit und bei sinnvoller Projektion ein auf maximal 70 Pixel begrenzter Ein-Sekunden-Geschwindigkeitsvektor. Kein Auto-Aim.
- **Rote Raute / MISSILE:** kurzfristig gefährlicher beobachteter Raketenanflug. `closing` ist die radiale relative Annäherungsgeschwindigkeit. `near ~… s` schätzt den Zeitpunkt der nächsten gefährlichen Annäherung im momentanen geradlinigen Bewegungsmodell; kein garantierter Einschlagscountdown.
- **PRIORITY + Ring:** bewusste Sensoroperator-Priorisierung, unabhängig vom primären Schiffsziel. Die nächstgelegene automatische Gefahr überschreibt diese Entscheidung nicht.
- **FRONT / SIDE / AFT:** Richtung relativ zur Schiffsnase, unabhängig von der Außenkamera. FRONT beziehungsweise AFT beginnen innerhalb eines 60°-Kegels. Zusätzlich kennzeichnet BEHIND VIEW ein Ziel hinter der aktiven Kamera.
- **Randpfeile:** gemessene Zielrichtung außerhalb der sicheren Anzeigezone. Hinten liegende Ziele werden nicht spiegelverkehrt projiziert. Exakt achteraus ist die Links-/Rechtswahl geometrisch mehrdeutig: ein deterministischer rechter Pfeil zusammen mit AFT macht diesen Sonderfall ausdrücklich erkennbar.
- **UNCERTAIN / age:** geringe Qualität, ältere Beobachtung oder verlorener Kontakt. Raute gestrichelt, Zahlen ausdrücklich geschätzt. Beschriftungen bleiben in vier festen freien Bereichen oberhalb der Cockpitinstrumente.

Höchstens **ein Schiffsziel und drei Raketenwarnungen** erscheinen gleichzeitig. Eine Crew-Priorität belegt den ersten Warnplatz; übrige Plätze folgen der geschätzten Annäherungszeit. Eine kleine Gesamtzahl meldet weitere Gefahren. Die Konsole zeigt bis zu fünf Kontakte gleichzeitig, mit dem ausgewählten Kontakt in einer nachgeführten Liste; alle Kontakte bleiben über links/rechts erreichbar. Senderrolle und Vergabezeit stehen neben beiden Designations. Auch die Waffenstation liest denselben taktischen Status im Kopfbereich.

## Sensorgrenzen

`ShipDesignations` akzeptiert ausschließlich kopierte feindliche `SensorContact`-Beobachtungen: ID, Art, gemessene Weltposition/-geschwindigkeit, Qualität, Messzeit und Trackingstatus. Keine Gegner-Nodes oder direkten Gegnerpositionen gelangen in die HUD-Datenebene. Eigene Lage und Geschwindigkeit stammen aus der kooperativen Schiffsnavigation; die aktive Kamera dient ausschließlich der Projektion.

Nichtendliche Daten, unbekannte/befreundete IFF, Qualität unter 0,25 und bereits mindestens 1,5 s alte Beobachtungen erzeugen keine neuen Tracks. Schlechte Qualität unter 0,65 wird unsicher angezeigt. Nach vollständigem Kontaktverlust bleibt die letzte kopierte Beobachtung höchstens **1,5 s seit ihrem Messzeitpunkt** erhalten; vorhandene gemessene Geschwindigkeit erlaubt eine kurze lineare Extrapolation. Ohne bekannte Geschwindigkeit bleibt die Position am letzten Messpunkt. Der Zeithorizont wird durch wiederholtes Lesen derselben alten Beobachtung nicht verlängert. Nach Ablauf werden Track und Designation entfernt.

Eine neue Designation setzt einen noch vorhandenen beobachteten Kontakt voraus. Verlorene, lediglich extrapolierte Tracks lassen sich nicht neu markieren. Eine bestehende Designation darf das kurze Verlustfenster überleben. Passives Beobachten ist von aktivem Waffen-Tracking getrennt: Tracking aus bedeutet nicht automatisch Sensorverlust, solange weiterhin frische passive Messungen vorliegen.

Automatische Solo-Warnungen verlangen bekannte Geschwindigkeit, mindestens 0,45 Qualität, positive Annäherung, geschätzte nächste Annäherung innerhalb 20 s und Abstand dabei höchstens 100 m. Diese konservative Sicherheitszone ist keine Trefferprognose. Ein bewusst priorisierter erkannter Flugkörper bleibt auch ohne brauchbare ETA hervorgehoben; unbekannte Geschwindigkeit liefert keinen Countdown. Kursänderungen und spätere Beschleunigungen können jede Schätzung ändern. Es wird keine neue perfekte Sicht-/Verdeckungsinformation eingeführt; die vorhandene Sensor-Simulation bleibt vereinfacht.

## Architektur und Ereignisse

`CombatEncounter.player_designations` ist der eigene taktische Zustand dieses Schiffs innerhalb der Mission. Keine globale Singleton-Abhängigkeit. `CrewDesignation` enthält Ziel-ID, Kategorie, Senderrolle und Simulationszeit; `ObservedTrack` enthält kopierte Messdaten und begrenzte Schätzfunktionen. `designation_changed` erzeugt außerdem bestehende taktische Ereignisse mit denselben Metadaten. Damit sind spätere Crewadapter/Host-Übertragung vorbereitet, aber kein Netzwerkcode implementiert.

Nur der Sensorstationsadapter nimmt in DESIGNATE Bedienbefehle entgegen. `CombatDisplay` und `TacticalHud` beobachten denselben Datenzustand; der HUD verändert weder Zielprioritäten noch Simulation. HUD-Marker sind Canvas-Geometrie und Labels, keine Körper im Weltraum. Geometrie folgt der aktiven Kamera pro Frame, numerischer Text wird auf 10 Hz begrenzt; Kategorien-/Zielwechsel und Unsicherheitswechsel aktualisieren sofort. Physik, Sucher, Flugcomputer, Waffenfreigaben und MANUAL/ASSISTED/FULL AUTO wurden nicht verändert.

## Tatsächliche Validierung

`GODOT_BIN=/pfad/zu/godot-4.7 ./tools/check.sh`: **574 bestandene Checks = 522 bestehende unveränderte Assertions + 52 neue**, zwölf PCM-Dateiprüfungen, Headless-Import und Starts von freiem Flug und Kontakt Alpha. Neue Prüfungen umfassen Vergabe/Wechsel/Entfernung, Rollen-/Zeitmetadaten, kopierte Beobachtungen statt exakter Körperdaten, Qualität/NaN/Freund-IFF/Alter, begrenzte Verlustextrapolation, reale Kameraprojektion einschließlich rückwärtiger Ziele, mehrere Raketen und Cluttergrenze, tatsächliche PS-Kontextwechsel und Sensor→Pilot-Sitzwechsel, erhaltene Drohnenbedienung und keine neuen MANUAL-Abschüsse.

Grafische Reproduktion:

```sh
DISPLAY=:94 godot --path . --rendering-method gl_compatibility \
  --audio-driver Dummy --resolution 1280x720 --fixed-fps 60 \
  --script res://tests/shared_hud_capture.gd
```

In einer eingeschränkten Cloud-Umgebung zusätzlich schreibbare XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME verwenden. Tatsächlicher Renderer: OpenGL Compatibility, Xvfb, Mesa 25.0.7 / llvmpipe LLVM 19.1.7. Acht unretuschierte Aufnahmen unter `docs/screenshots/shared-*.png`: normale Drohnenbefehle, Designation, Pilotenziel, Priorisierungskonsole, mehrere Warnungen, Außenkamera/Randpfeile, unsichere Daten und abgelaufene Daten.

Der Renderaufbau startet eine normale Seed-71-Mission und führt echte Stations-/Markierungsbefehle aus. Für reproduzierbare gleichzeitige Gefahren werden vier echte, unbeschleunigt anfliegende Raketen initialisiert; anschließend liest das HUD ausschließlich die tatsächlichen Sensorsamples. Ein expliziter Sensor-Blackout im Testaufbau erzeugt die Unsicherheits-/Verlustaufnahmen. Es werden keine HUD-Sensorkontakte erfunden oder Screenshottexte nachbearbeitet.

Erste Aufnahmen zeigten Text über Cockpitinstrumenten und erneut fehlende llvmpipe-Glyphenfragmente. Feste Beschriftungsplätze, separate Rasterfont-Daten für Konsole/HUD, der Verzicht auf Textschatten und begrenzte Textaktualisierung adressieren diese konkreten Befunde. Die abschließenden Aufnahmen zeigen vollständige Ziel-/Prioritäts-/Unsicherheitstexte; eine uneingeschränkte Langzeit-Grafikabnahme wird daraus nicht abgeleitet. Der Software-Renderer meldet erwartungsgemäß nicht unterstütztes VSync. Eine begrenzte Capture-Sequenz ist keine Garantie für jede GPU oder Langzeitsitzung.

**Nicht durchgeführt:** physischer DualSense-/Xbox-Test, menschlicher Spiel-/Hörtest, native GPU-Messung oder Plattformexport. Empfohlene nächste Aufgabe: Desktop-Abnahme von Richtungsverständlichkeit, gleichzeitigen Warnungen und L2+R3 mit echtem Controller.
