# Milestone 0.3.3 — Bedienung und Abnahme

Basis: `96d26bc`, `feature/milestone-0.3.2-flight-ps-sound`. Godot **4.7.stable.official.5b4e0cb0f**, GDScript, weiterhin 60-Hz-Physik. Keine neuen Netzwerk-, HAMMER- oder Fernzündungssysteme. Physik und Pilotenkontrollen bleiben erhalten.

## PlayStation-first: getrennte Kontexte

Die Hinweise folgen Auto/PlayStation/Xbox beziehungsweise Maus/Tastatur. Options pausiert jederzeit. ✕ / F betritt oder verlässt die Station; Dreieck / V schaltet die Außenkamera. Normale Rollenfreigabe und Sicherheitsgurte bleiben im Feuerleitungskontext erhalten. **Kreis bedeutet in Karte/Raketenansicht Rückkehr zur Feuerleitung**, nicht Gurt lösen. Die kontextspezifischen Hinweise ersetzen dort die allgemeinen Gurtkurzbefehle.

| Feuerleitung | PlayStation | Tastatur |
|---|---|---|
| Kontakt wählen | Steuerkreuz links/rechts | Pfeile links/rechts |
| Tracking umschalten | Quadrat | T |
| Rack wechseln | Steuerkreuz oben | L |
| Sicher/scharf | Steuerkreuz unten | K |
| Genau eine Rakete starten | R1, loslassen für nächsten Start | R |
| Eigene Raketenansicht, zunächst AUTO VIEW | L1 | H |
| 3D-Karte | Share/Create | Tab |
| Rollenfreigabe, nur ASSISTED/FULL AUTO | R3 | O |

| 3D-Karte | PlayStation | Tastatur/Maus |
|---|---|---|
| Orbit | linker Stick | WASD oder Maus |
| Zoom | R2 näher / L2 weiter | Mausrad |
| Kontakt wählen, auch eigene Einheiten | Steuerkreuz links/rechts | Pfeile links/rechts |
| Ausgewähltem Kontakt folgen | Quadrat | T |
| Ansicht zurücksetzen | R3 | O |
| Zur Feuerleitung | Kreis oder Share/Create | Esc oder Tab |

| Raketenansicht | PlayStation | Tastatur/Maus |
|---|---|---|
| Eigene aktive Rakete wählen | Steuerkreuz links/rechts | Pfeile links/rechts |
| MANUAL/AUTO ausdrücklich umschalten | R3 | M |
| Pitch/Yaw in MANUAL | linker Stick | Maus |
| Seiten-/Vertikal-RCS in MANUAL | rechter Stick | A/D, Space/Shift |
| Hauptschub in MANUAL | R2 proportional | linke Maustaste |
| Rollen in MANUAL | L1/R1 | Q/E |
| Zur Feuerleitung, Rakete wieder AUTO | Kreis oder Share/Create | Esc oder Tab |
| Zusätzlich zurück in AUTO VIEW | L1 | H |

R1 schießt in Karte/Raketenansicht **keine neue Rakete** ab. L1 ist nur in MANUAL Rollsteuerung. Pause, Stations-/Gerätewechsel und Moduswechsel löschen alte Anforderungen; gehaltene Flugkanäle müssen zunächst neutral werden. Kameras bewegen ausschließlich Kameraknoten. Raketenverlust oder ein einfacher 4-km-Linkabbruch gibt AUTO zurück. Keine Fernzündung.

Drohnenkonsole unverändert: Steuerkreuz oben = starten; unten = nächster trägerrelativer Wegpunkt; R1 = DEFEND an/aus; L1 = inertial HOLD; Share/Create = RECALL; R3 = ausdrückliche Rollenfreigabe. Kontaktwahl und Tracking wie Feuerleitung. Xbox verwendet entsprechende LB/RB, LT/RT, LS/RS, A/B/X/Y und Back/Start. Die vorhandenen Pilotenkontrollen bleiben unverändert.

## Karte und manuelle Lenkung

Die Karte ist eine reine Mesh-Darstellung in einem isolierten SubViewport auf der physischen Konsole, kein zweites Physikuniversum. Einheitenmaßstab: 100 m pro Karteneinheit, Koordinaten relativ zu DRIFTs aktueller Ausrichtung. Blau = eigenes Schiff, Grün = kooperative Einheiten, Orange = beobachtete Gegner. Linien zeigen Geschwindigkeit für eine Sekunde; gestrichelte Linien prognostizieren höchstens vier Sekunden; transparente Endkugeln kennzeichnen zunehmende heuristische Unsicherheit. Unzureichende Messqualität unterdrückt unbekannte Geschwindigkeiten/Prognosen. Kontakte ab 1,5 s Alter verschwinden. Die Unsicherheit ist keine statistisch kalibrierte Wahrscheinlichkeit. Beschleunigte Gegner können anders manövrieren; keine Zukunftskenntnis.

Eigene Körper liefern echte bekannte Zustände. Fremde Einheiten gelangen nur über `SensorContact` in das Modell; auch versehentlich übergebene fremde Körper werden nicht als kooperative Daten akzeptiert. Neue Beobachtungen ersetzen alte Prognosen mit 10 Hz. Raster, Höhenlinien und Orbit machen die dritte Dimension sichtbar; Tags werden bei Überlappung versetzt.

Manuelle Raketenbefehle durchlaufen eine **11-Tick-/183-ms-Verzögerung**. Maximal angeforderte Winkelrate 1,2 rad/s; begrenzte Winkelbeschleunigung 4 rad/s²; integrierte Steuerreserve anfangs 12 rad/s. Seitliche Beschleunigung höchstens 55 m/s², gesamter Schub höchstens 14.400 N. Tatsächliche Kraft verbraucht den bestehenden endlichen Delta-v-Vorrat. AUTO verwendet weiterhin den beobachtungsbasierten Sucher und dieselbe endliche Steuerreserve. Bei erschöpften Reserven bleibt der Körper mit seiner realen Geschwindigkeit unterwegs. Kein Setzen von Pose oder Geschwindigkeit durch Bedienung. Vereinfachung: abstrakte Steuerreserve statt detailliertem Düsen-/Treibstoffmodell, feste Linkverzögerung statt Funk-/Störsimulation.

## Abwehr: nachvollziehbare Grenzen

Bisher waren mechanische Ausrichtung und Zielwechsel praktisch sofort möglich. Jetzt: 0,16 s Erstreaktion, 0,22 s Zielwechsel, maximal 3 rad/s Schwenkrate, 0,025 rad Zielkegel, Zweischuss-Burst und 0,65 s Erholung. Sensoralter/-qualität, echte Geschützreichweite, bestehende profilabhängige Kadenz, endliche Munition und physikalische Abfanggeschosse bleiben maßgeblich. Keine Zufalls-Durchlassquote. Die Drohne dreht ihren Geschützvektor begrenzt; ein animierter Geschützturm ist noch nicht modelliert.

Ein Timingfehler wurde beim neuen Messverfahren explizit geprüft: Abwehrsensoren messen die aktuelle Solver-Position innerhalb der Sensorgrenze; Geschwindigkeit/Beschleunigung entstehen weiterhin aus quantisierten Beobachtungsdifferenzen. Der alte zusätzliche Extrapolationstick wird nur für gecachte Node-Positionen verwendet. Sonst zielte der Schütze beim 450-m/s-Test einige Meter zu weit voraus.

### Reproduzierbare physikalische Versuche

`tests/defense_trial.gd`, Daten in [defense-0.3.3.json](defense-0.3.3.json): identische echte Träger-, Raketen- und Drohnenkörper; drei gleichzeitige Anflüge aus verschiedenen Winkeln, 700 m / 450 m/s. Nur Ausgangsaufstellungen, keine injizierten Treffer oder Sieger.

| Aufstellung | Abgefangen | Treffer | Trägerhülle |
|---|---:|---:|---:|
| Keine Drohne, drei Anflüge | 0 | 3 | 0 % |
| Gute Guard-Position, drei Anflüge | 1 | 2 | 32 % |
| Schlechte Position 900 m achteraus | 0 | 3 | 0 % |
| Gute Guard-Position, ein Anflug | 1 | 0 | 100 % |
| Gegenprobe ohne Reaktions-/Schwenk-/Burstlimits | 2 | 1 | 66 % |

Die Gegenprobe deaktiviert dieselben neuen Grenzparameter; sie ist kein nachgestellter Lauf der alten Binärversion. Gute Guard-Position verbraucht im Dreifachversuch einen echten Schuss und 54,873 m/s Deployment-Delta-v; hintere Position 360,165 m/s und null Schüsse. Maximales gemessenes Schwenken: ungefähr 0,05 rad pro Tick. Sättigung ist ausdrücklich weiterhin tödlich.

### Vollständiges Kontakt-Alpha-Gefecht

Reproduktion: `godot --headless --fixed-fps 60 --path . --script res://tests/tactical_battle_report.gd` unter Godot 4.7. [Rohdaten](tactical-battles-0.3.3.json). MANUAL / NORMAL; echter normaler Schaden, gleiche explizite Bedienbefehle. Der Operator verfolgt/schärft, fordert 4 s Vorwärts-RCS an, rollt aus und fordert bei 10–13,333 s Rückwärts-RCS an. Rackpaare alle acht Sekunden mit zweitem Start 0,2 s später, soweit die reale Feuerleitung erlaubt. Guard: Start bei 3 s, DEFEND bei 3,2 s. Schlechte Position: gleicher Auftrag, aber Wegpunkt (0,−30,+900) m. Keine Zustandskorrekturen während des Gefechts.

| Seed | Plan | Ergebnis / Dauer | Eigene Hülle | Eigene Abfänge |
|---|---|---|---:|---:|
| 71 | ohne Drohne | DEFEAT / 41,52 s | 0 % | 0 |
| 71 | Guard | VICTORY / 32,22 s | 66 % | 1 |
| 71 | achteraus | DEFEAT / 41,52 s | 0 % | 0 |
| 1741 | ohne Drohne | VICTORY / 32,38 s | 32 % | 0 |
| 1741 | Guard | VICTORY / 32,38 s | 100 % | 2 |
| 1741 | achteraus | VICTORY / 32,38 s | 32 % | 0 |

Das sind feste reproduzierbare Szenarien, keine allgemeine statistische Siegquote. MANUAL startet weiterhin nichts ungefragt. ASSISTED SOLO führt nur ausdrücklich delegierte Rollen aus; FULL AUTO bleibt ein eigener Demonstrationsmodus.

## Audio und Validierung

Originale CC0-Synthese bleibt erhalten. Hauptantrieb läuft kontinuierlich mit tatsächlicher Leistung und geglättetem Pegel. RCS ist eine kurze sanft ausblendende Aktivitätshülle über einem leisen periodischen Signal, statt wiederholter Explosionsattacken. Das verändert keine Kräfte. Reservierte Warnstimme priorisiert Einschlagsalarm, begrenzte Wiederholung (0,65–2 s) und kurzes Ducking des Schiffsklangs; keine ununterbrochene Alarmtonschleife. Master-Limiter und gespeicherte Master/Ship/Warnings/UI-Einstellungen bleiben erhalten.

Realer AudioServer-Test mit Dummy-Ausgang: `godot --headless --audio-driver Dummy --path . --script res://tests/audio_balance_capture.gd -- --audio-headless`. In eingeschränkten Umgebungen schreibbare XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME setzen. WAVs entstehen unter `/tmp/drift033-*`; gemessene Pegel in [audio-0.3.3.json](audio-0.3.3.json). Audioeffekt-Aufzeichnung erfolgt nach Effekten, vor jeweiligem Busgain; Master ist die resultierende Mischung. Hauptantrieb deutlich über häufigem RCS; Warnung hebt sich über geducktem Schiffsklang ab. Kein menschlicher Hörtest.


| Mixerphase | Ship RMS | Warnings RMS | Master Peak |
|---|---:|---:|---:|
| main | 0.08773 | 0.00000 | 0.10162 |
| frequent-rcs | 0.00780 | 0.00000 | 0.01321 |
| urgent-warning | 0.06212 | 0.11147 | 0.34628 |
| vacuum | 0.00000 | 0.00000 | 0.00000 |

Hauptantrieb gegenüber häufigem RCS: 11.25-facher Ship-RMS-Pegel / 21.0 dB. Master-Spitze bei Warnung 0.346, unter der Limitergrenze. Zeitfenster/Puffergrenzen können bei erneutem wall-clock Lauf geringfügig variieren.

Automatischer Standardlauf: `GODOT_BIN=/pfad/zu/godot-4.7 ./tools/check.sh`: Import, beide Szenenstarts, alle **475 bisherigen und 47 zusätzlichen Checks**, außerdem zwölf PCM-Dateiprüfungen. Die bisherigen 59 Audio-/Controller-Assertions bleiben erhalten; deren langer Munitions-/Eingabe-Soak verwendet jetzt ausdrücklich erhöhte Komponentenhaltbarkeit im Testaufbau, damit geänderte Drohnenabwehr ihn nicht vor allen 16 Starts beendet. Das ist kein normaler Balanceversuch. Obige Gefechte und neue Abwehrtests verwenden normale Spielgesundheit.

Echte OpenGL-Compatibility-Aufnahmen bei 1280×720, Xvfb/Mesa25/llvmpipeLLVM19: `tests/tactical_capture.gd`, sechs unretuschierte [Ansichten](screenshots/tactical-fire-control.png) mit `tactical-`-Präfix. Textänderungen werden jetzt außerhalb von `_draw` auf native wiederverwendete Labels übertragen. Die neuen Feuerleitungs-, Karten-, Raketen- und Drohnenaufnahmen wurden visuell geprüft; darin kein Verschwinden ganzer Textzeilen. Das ist eine begrenzte Software-Renderer-Prüfung, keine Garantie für alle Laufzeiten oder GPUs. Erwartete VSync-Warnung unter Xvfb.

**Nicht durchgeführt:** echter PlayStation-/Xbox-Hardwaretest, menschlicher Desktop-Spieltest, menschlicher Hörtest, natives GPU-Profiling oder Export. Controllerereignisse und PS-Schema wurden synthetisch getestet. Eine gemeinsame Hardware-Abnahme von Lautstärke, Sticklenkung, Kartenlesbarkeit und langen Gefechten ist der nächste empfohlene Schritt.
