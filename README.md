# DRIFT · Milestone 0.3.3 — Tactical Combat & Missile Control

Spielbarer **Godot-4.7-/GDScript-Desktop-Prototyp**: begehbares 36-m-Schiff, First Person, Pilotensitz, physikalischer Newtonscher 6DOF-Flug, Xbox-/PlayStation-Eingaben, abschaltbarer Flugcomputer und drei physisch montierte Cockpitinstrumente. Kontakt Alpha ergänzt ein echtes physikalisches Gefecht mit Gegner, Raketen und Abwehrdrohne. Drei besetzbare, sicherbare Crewstationen, beobachtungsbasierte Sensorik, simulierte Feuerleitung und zentrale Crew-Schubsicherheit. Sämtliche Geometrie entsteht aus Godot-Primitiven; keine externen Assets, Plugins oder Dienste.

## Neu in 0.3.3

Die Waffenstation besitzt jetzt eine echte orbitierbare **3D-Gefechtskarte** auf ihrem Konsolenbildschirm sowie eine ausdrücklich aktivierbare **manuelle Raketensteuerung**. Eigene Einheiten liefern Navigationsdaten; Gegner erscheinen ausschließlich aus aktuellen Sensormessungen. Vektoren, maximal vier Sekunden Prognose und wachsende Unsicherheit sind gekennzeichnet. Reaktionszeit, endliche Schwenkrate, Zielwechsel und Feuerpausen begrenzen die physikalische Drohnenabwehr. Hauptantrieb, sanft gebündeltes RCS und priorisierte Einschlagswarnungen wurden im echten Audiomixer neu abgestimmt.

**Aktuelle vollständige Kontextbelegung, Messergebnisse, reproduzierbare Gefechte und Grenzen:** [Milestone 0.3.3](docs/tactical-0.3.3.md). Die folgenden 0.3.2-Abschnitte dokumentieren den bisherigen Stand; insbesondere ist H/L1 jetzt der Einstieg in die Raketenansicht, nicht mehr ausschließlich eine Beobachtungsfunktion.

## Neu in 0.3.2

PlayStation-first: Erkannte DualSense-/DualShock-/Sony-/PS4-/PS5-Geräte zeigen **✕, Kreis, Quadrat, Dreieck, L1/L2/L3, R1/R2/R3, Options und Share/Create**. Xbox erhält eigene Hinweise. Unter **Options → Audio / Controller symbols** lässt sich das Schema Auto / PlayStation / Xbox manuell auswählen. Die untenstehenden Vergleichstabellen dokumentieren weiterhin beide Controller. Laufende Konsolen zeigen nur das aktive Schema beziehungsweise Tastaturbefehle.

Die Waffenstation priorisiert Ziel, Track/Lock, großen Sperrgrund, Munition und **NEXT**. Die Drohnenstation zeigt eine größere X-Z-Karte: blaues Dreieck = DRIFT, grünes Quadrat = eigene Drohne, grüner Kreis = tatsächliche 420-m-Geschützreichweite, orange Punkte = beobachtete feindliche Raketen. Der aktuelle Auftrag, Vorräte und passende Befehle stehen daneben. Kontakte außerhalb der 1,2-km-Kartenskala werden am Rand dargestellt; ein außerhalb liegender Drohnenradius wird nicht als örtlich korrekter Kreis ausgegeben.

**MAIN THRUST / BRAKE RCS / NET ACCELERATION** erscheinen im Pilotenstatus. Zusätzlich werden Hauptantriebszustand und manuell angeforderter Rückwärtsschub angezeigt. Gesund liefert R2 weiterhin **2,4 MN / 20 m/s²**. Ein Treffer am Hauptantrieb hinterlässt **49 % / 1,176 MN / 9,8 m/s²**, auch ohne jede Bremskraft. Das war eine nachweisbare Ursache scheinbaren Gegenschubs; eine Bremsung nach tatsächlichem Loslassen ließ sich nicht reproduzieren. L2+R2 gleichzeitig ist dagegen ausdrücklich angeforderter Gegenschub: **20 − 12 = 8 m/s²**. Die Physik und Leistungsgrenzen wurden nicht erhöht. Beim Pause-/Stationswechsel müssen bereits gehaltene Flugkontrollen erst losgelassen beziehungsweise zentriert werden. Danach funktionieren neue Eingaben sofort; Gerätewechsel und Abziehen entfernen alte Controller-Aktionszustände.

Zwölf originale **CC0-Sounds** ergänzen strukturellen Hauptantrieb, RCS-Impulse, Rack-Ausstoß, Treffer/Systemschäden, Sensorhinweise, annäherungsabhängigen Raketenalarm, Bedienung/Bestätigung, Drohnenmechanik und Sieg/Niederlage. Im Innenraum haben Körperschallquellen räumliche Positionen; Außenkameras hören keine gewöhnlichen Gefechtsgeräusche durch das Vakuum. Elektronische Warnungen und Bedienung bleiben als Bordkommunikation verfügbar. **Master / Ship / Warnings / UI** sind unabhängig regelbar und werden gespeichert. Die Hauptantriebslautstärke folgt der tatsächlich angewandten Leistung mit sanften Übergängen. Kein Controller-Rumble ist implementiert; die Startvibration ist akustisch gestaltet.

**Options → Disengage / Mission abbrechen** beendet den Einsatz bewusst ohne Abschusswertung. Beidseitig fehlende offensive Restbewaffnung führt erst **nach allen aktiven Raketen plus 5 s Ruhefrist** zum **Unentschieden**. Die Drohnengeschütze sind reine Raketenabwehr und können keine Schiffe bekämpfen. Einseitig leere Racks, fehlender momentaner Lock oder geringe Entfernung allein beenden nichts. Kampfunfähigkeit durch Schäden bleibt Sieg/Niederlage; ein nicht mehr entscheidbares Gefecht bei noch vorhandenen, aber unerreichbaren Waffen lässt sich bewusst abbrechen.

**Bekanntes Grafikproblem:** Unter dem hiesigen Mesa/llvmpipe-Software-Renderer fehlen bei laufenden Konsolenupdates vereinzelt Textteile, sichtbar unter anderem im Abschuss-Screenshot. Die Bilder sind unverändert; eine vollständige grafische Abnahme wird nicht behauptet. Ein echter GPU-/PlayStation-Test steht aus.

Gerenderte 1280×720-Ansichten: [Sperrgrund](docs/screenshots/ps-weapons-blocked.png), [READY](docs/screenshots/ps-weapons-ready.png), [Abschuss](docs/screenshots/ps-launch.png), [Drohne](docs/screenshots/ps-drone.png), [Pilot](docs/screenshots/ps-pilot.png), [Pause](docs/screenshots/ps-pause.png), [Audio/Symbole](docs/screenshots/ps-audio-symbols.png), [Abbruch](docs/screenshots/ps-disengage.png). [Diagnose und Testergebnisse](docs/validation.md).

## Kontakt Alpha starten

**P / Start/Options → Kontakt Alpha / Mode + difficulty** öffnet das Missionsmenü. Wähle Modus, Schwierigkeit und optional einen reproduzierbaren Seed; dann **Start mission**. Standard ist **MANUAL / NORMAL**, Seed 0 erzeugt einen neuen Seed, der in der Mission angezeigt wird. Alternativ im Godot-Editor `scenes/contact_alpha.tscn` mit F6 starten oder `godot --path . res://scenes/contact_alpha.tscn`. `scenes/main.tscn` und der normale Projektstart bleiben freier Flug; der Menüpunkt **Freier Flug** führt zurück. Nach Sieg/Niederlage lässt sich die Mission mit dem fokussierten Button neu starten (Enter bzw. A/Kreuz).

Du beginnst auf deiner begehbaren Brücke; ALPHA steht etwa 1,1 km entfernt und bewegt sich physikalisch mit eigenem KI-Piloten. Beide Schiffe besitzen je **zwei Raketenracks mit vier Raketen**. **MANUAL:** Ohne deinen ausdrücklichen Startbefehl fliegt keine eigene Rakete und startet keine Drohne. Sensorabtastung, Feuerlösungen, Warnungen und die Ausführung deiner bestehenden Aufträge laufen weiter.

**ASSISTED SOLO:** Nur ausdrücklich freigegebene Rollen dürfen handeln. Die Waffenfreigabe im Missionsmenü erlaubt automatische Starts an der unbesetzten Waffenstation. Die Drohne muss weiterhin von dir gestartet und positioniert werden; ihr DEFEND-Auftrag darf erkannte Bedrohungen selbst abfangen. Eine nachträglich erteilte Drohnen-Rollenfreigabe kann einer bereits gestarteten Drohne DEFEND zuweisen. Es gibt keine versteckte Startwarteschlange.

**FULL AUTO / DEMO:** Automatische Starts, Drohnenbereitstellung und Verteidigungsauftrag wie im früheren Demonstrationsmodus. Bewusst auswählen; kein Standard. Jede Stationsübernahme entzieht ihrer Rollenautomatik sofort die Befehlsgewalt und sichert die Waffen. Bereits gestartete Flugkörper und ausdrücklich erteilte Drohnenaufträge laufen weiter. Der tatsächliche Modus und die aktuelle Befehlsgewalt stehen dauerhaft auf beiden Konsolen.

### Waffenstation (rechts)

| Funktion | Tastatur | Controller Xbox / PlayStation |
|---|---|---|
| Station betreten/verlassen | F | A / Kreuz |
| Kontakt auswählen | Pfeile links/rechts | D-pad links/rechts |
| Kontakt verfolgen | T | X / Quadrat |
| Port-/Steuerbord-Rack wechseln | L | D-pad oben |
| Sicher / scharf | K | D-pad unten |
| **Rakete abfeuern** | **R** | **RB / R1** |
| Fliegende eigene Rakete beobachten / zurück | H | LB / L1 |
| Rollenfreigabe an/aus (ASSISTED/FULL AUTO) | O | RS-Klick (in Konsolenansicht) |

Wähle **ALPHA / ship**, aktiviere **T/X: TRACKING** und lasse etwa zwei Sekunden eine Feuerlösung aufbauen. Die Messqualität verbessert sich durch fortgesetztes Tracking. Ab vollständigem Aufbau und mindestens 70 % Lock Quality wähle das Rack, schalte mit **K/D-pad unten** scharf und feuere bei **READY** bewusst mit **R/RB**. Bei Ziel-/Trackingverlust wird die Lösung verworfen. Unzureichende/veraltete Messungen, unbekannte Geschwindigkeit, befreundete IFF, leere Racks, Nachladezeit oder ausgefallene Waffen verhindern den Abschuss. Nachladezeit gesund **6 s pro Rack**, unabhängig voneinander. Für ein bewusstes Raketenpaar: R drücken und loslassen, L zum anderen Rack, erneut R drücken. Halten, Tastatur-Wiederholung oder doppelte Press-Ereignisse erzeugen keine automatische Salve. Der Bildschirm zeigt TRACKING, LOCK QUALITY, Rack/Munition, READY oder einen konkreten Sperrgrund, IN FLIGHT mit Auftraggeber PLAYER/ROLE AI sowie HIT, MISS oder INTERCEPTED. Eine nächste sinnvolle Eingabe wird eingeblendet. Die Feuerleit-ETA ist nur ein vereinfachtes 300-m/s-Modell; die echte Rakete beschleunigt und lenkt mit begrenztem Schub und kann verfehlen. H/LB benutzt eine reine Beobachtungskamera; Schiff und Rakete bleiben physikalisch simuliert. V/Y erhält die bisherige Außenkamera; RS hält dort weiterhin den Kamera-Modifier und schaltet keine Automatik um.

### Sensor-/Drohnenstation (links)

| Funktion | Tastatur | Controller Xbox / PlayStation |
|---|---|---|
| Kontaktwahl / Tracking | Pfeile / T | D-pad links/rechts / X bzw. Quadrat |
| BLUE-D1 starten, wenn angedockt | L | D-pad oben |
| Nächsten trägerrelativen Wegpunkt zuweisen | K | D-pad unten |
| Aktuelle inertiale Position halten | H | LB / L1 |
| **Raketenabwehr an/aus** | **R** | **RB / R1** |
| Physisch zurückrufen | C | Back / Share |
| Unterstützung für unbesetzte Station an/aus | O | RS-Klick (Konsolenansicht) |

Es gibt eine Drohne mit drei erreichbaren Wegpunkten, **60 Abwehrgeschossen** und **650 m/s Delta-v**. Sie muss gegnerische Raketen selbst beobachten und trifft mit echten begrenzten Abwehrgeschossen; kein Schutzschild. Rückruf beendet die Abwehr und automatische Neustarts. Die Drohne dockt erst nach tatsächlicher Rückkehr mit kleiner Relativgeschwindigkeit an; Munition und Treibstoff bleiben verbraucht. Bei leerem Treibstoff kann sie driften und den Rückweg verfehlen. **ESCORT** folgt einem relativen Wegpunkt mit ausgeschaltetem Geschütz. **K/D-pad unten** weist den nächsten Wegpunkt zu und kehrt zu ESCORT zurück. **R/RB** erteilt **DEFEND** beziehungsweise beendet den Auftrag: Innerhalb tatsächlicher 420 m Geschützreichweite bekämpft die Drohne beobachtete, anfliegende Raketen, die DRIFT gefährden. Der Ring auf der Karte zeigt ihre örtliche Reichweite, nicht eine Schutzgarantie. **H/LB: HOLD** hält den aktuellen inertialen Punkt ohne Abwehr. **C/Back: RECALL** kehrt physisch zurück und verhindert automatische Neustarts.

Die Wegpunkte sind `(-60,20,-80)`, `(140,30,-140)` und `(0,-30,900)` m relativ zum Träger. Der hintere Punkt ist erreichbar, schützt aber oft zu spät gegen Angriffe von vorn. Die Anzeige nennt Auftrag, relative Position, Reichweite, erkannte feindliche Raketen, Munition und Treibstoff. Die eigene Drohnenposition kommt über eine kooperative Verbindung; feindliche Ziele bleiben Sensorbeobachtungen.

**Gurt U/B-Kreis, Gefechtsfreigabe J/LS-Klick, Stationswechsel F/A und die komplette Piloteneingabe bleiben erhalten.** Die neuen Kampfbefehle gelten nur an ihrer jeweiligen Konsole. Schäden wirken auf Rumpf, Hauptantrieb, RCS, Sensoren und Waffen. Wenige Treffer machen ein Schiff kampfunfähig; eine Explosion ist nicht nötig. Schaden färbt betroffene Schiffsgeometrie dunkelrot, die Konsole nennt die verbleibende Systemleistung.

Historische 0.3-Ansichten (FULL AUTO): [Raketenstation](docs/screenshots/contact-weapons.png), [Drohnenstation](docs/screenshots/contact-drone.png), [echter Raketenflug](docs/screenshots/contact-missile-flight.png), [Gefechtsende](docs/screenshots/contact-victory.png), [Modusauswahl](docs/screenshots/contact-mode-menu.png). Diese bei 1280×720 gerenderten Bilder wurden visuell geprüft; es gab keinen interaktiven Desktop-/Controller-Hardwaretest.

## Gegner und Schwierigkeit (0.3.1)

EASY/NORMAL/HARD verändern Reaktionszeit, Sensorabtastung/-auflösung, Ausweichintensität und begrenzte Abwehrmunition. Rumpfwerte, Schaden, Schiffsmasse und Raketenphysik bleiben gleich. ALPHA besitzt eine eigene physisch eingesetzte Abwehrdrohne und reagiert über seine Sensorbeobachtungen auf anfliegende Raketen. Es gibt keine Trefferboni oder Positionskorrekturen.

Pilotieren ist relevant: kurze Annäherung verkürzt die gegnerische Reaktionszeit; starke seitliche Beschleunigung kann einen Angriff vereiteln, erschwert aber auch die eigene Feuerlösung und kann das Gefecht außer Sensorreichweite führen. Munition, Rackwahl, Schussabstand und Drohnenposition sind echte Entscheidungen. Beidseitig erschöpfte Angriffswaffen werden seit 0.3.2 nach Ende der letzten Rakete als Unentschieden aufgelöst.

[Balancing-Bericht mit 26 reproduzierbaren Gefechten](docs/balance-0.3.1.md), [Messdaten](docs/balance-0.3.1.json). Sechs neue gerenderte Ansichten: [Missionsmenü](docs/screenshots/agency-mission-menu.png), [Rollenfreigaben](docs/screenshots/agency-assisted-consent.png), [READY](docs/screenshots/agency-weapon-ready.png), [bewusster Abschuss](docs/screenshots/agency-missile-ordered.png), [ESCORT](docs/screenshots/agency-drone-escort.png), [DEFEND](docs/screenshots/agency-drone-defend.png).

## Crewstationen und Sicherheit (0.2)

Auf der Brücke stehen links die **Sensor-/Drohnenkonsole**, rechts die **Waffen-/Feuerleitkonsole** und vorne der bisherige Pilotensitz. **F** bzw. **A/Kreuz** besetzt die nächstgelegene freie Station (3 m) und sichert automatisch den Gurt. Dieselbe Taste verlässt die Station. Der Mittelgang führt durch den kurzen Korridor zu Maschinenbaugruppen, Serviceleitungen und Wartungsflächen im Heck. Keine externen Assets.

| Neue Funktion | Tastatur | Xbox / PlayStation |
|---|---|---|
| Gurt sichern/lösen, ohne aufzustehen | U | B / Kreis |
| Gefechts-Schubfreigabe anfordern/zurücknehmen | J | Linken Stick drücken |
| Kontakt wählen, an taktischen Konsolen | Pfeil links/rechts | D-pad links/rechts |
| Zielverfolgung an/aus, an taktischen Konsolen | T | X / Quadrat |

Die Sensoranzeige zeigt schiffslokale relative Position, Entfernung, ID, geschätzte relative Geschwindigkeit, Qualität und Messalter. Grün bedeutet erfasst, Orange unzureichend erfasst. Drei passive Testziele werden alle 0,5 s bis 2,5 km beobachtet; die erste Messung kennt noch keine Geschwindigkeit. **T** aktiviert die Verfolgung des gewählten Kontakts; anschließend kann die Waffenstation eine simulierte Abfanglösung aus denselben Beobachtungen anzeigen. Im freien Flug bleiben die Waffenplätze leer/inert und Starts gesperrt. Echte Raketen und Drohnen gibt es ausschließlich in Kontakt Alpha.

**Normalbetrieb begrenzt die insgesamt angeforderte lineare Eigenbeschleunigung auf 3 g**, unabhängig davon, wie viele Schubkanäle gleichzeitig aktiv sind. Nach J ist bis 8 g nur erlaubt, wenn alle anwesenden Crewmitglieder an geeigneten Stationen gesichert sind. Sonst erscheint **HIGH-G DENIED / CREW UNSECURED**. Bestehende Geschwindigkeit, externe Kollisionsimpulse und die bisherigen Drehmomente werden nicht begrenzt. Die realen Triebwerkswerte bleiben unverändert: der Hauptantrieb liefert weiterhin 20 m/s² (ca. 2,04 g), auch bei Gefechtsfreigabe. Mit den aktuellen Antrieben ist deshalb kein sichtbarer 3-g-Leistungsabfall zu erwarten; die Freigabeverweigerung ist dennoch sichtbar.

Die normal sichtbare Statuszeile nennt Station, Gurt und Schubfreigabe; F3 behält alle technischen Daten. Pilot und taktische Konsolen haben getrennte Eingabekontexte. Frei umbelegte erweiterte Pilotentasten behalten dort Vorrang; gegebenenfalls eine konfliktfreie Belegung wählen. Pause/Options und der Menüweg zum Verlassen bleiben verfügbar.

Ansichten: [Brücke](docs/screenshots/crew-bridge.png), [Sensorstation](docs/screenshots/crew-sensors.png), [Feuerleitung](docs/screenshots/crew-weapons.png), [Pilot/Sicherheit](docs/screenshots/crew-pilot-safety.png), [Maschinenraum](docs/screenshots/crew-engineering.png). Reproduzierbar mit `godot --path . --audio-driver Dummy --resolution 1280x720 --script res://tests/crew_capture.gd` auf einem grafischen Display.

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

Beim Start gibt es **keine permanente Debug-Textwand**. **F3** blendet die bisherigen technischen Daten und das Debug-Menü gemeinsam ein/aus. Außerhalb der Displays erscheinen die kontextuelle Stationsaufforderung beziehungsweise Station/Gurt/Schubfreigabe. Drei geneigte, gerahmte Bildschirme mit Sockeln sitzen unterhalb der normalen Piloten-Sichtlinie; dieselben Texturen sind auch am lokalen Brückenpult zu sehen.

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
- `crew_controller.gd`, `crew_station.gd`, `crew/`: lokale Bewegung, Stationsidentität, Crew und zentrale Schubsicherheit.
- `tactical/`: Sensorbeobachtungen, Feuerleitmodell und physische Konsolenanzeigen.
- `combat/`: separate Mission, feindlicher Pilot, physische Raketen/Drohne/Abwehrgeschosse, Launcher, Komponentenschäden und strukturierte Events.
- `test_arena.gd`, `exterior_orbit.gd`: statische Referenzen und unabhängige Kameradarstellung.
- `pause_menu.gd`: Controller-/Maus-/Tastatur-Menüs.
- `scripts/instruments/`: typisiertes `ShipTelemetry`-Snapshot, gemeinsame Display-Zeichenbasis, drei getrennte Instrumente und wiederverwendbare Cockpit-Montage.
- `scripts/audio/`, `assets/audio/`: beobachtungsbasiertes, szenengebundenes Audio und selbst erzeugte CC0-WAVs.
- `controller_labels.gd`: zentrale dynamische PS-/Xbox-Beschriftung.
- `tests/`: zehn Suiten mit **475 Prüfungen** (416 unveränderte bisherige und 59 neue Flug-/PS-/Audio-/Missionsregressionen) und optionale Mix-/Render-Fixtures.

```bash
# Linux x86_64; benötigt curl, unzip und sha512sum:
./tools/bootstrap_godot.sh
GODOT_BIN=/workspace/tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 ./tools/check.sh
```

Der Bootstrap installiert die offizielle, SHA512-geprüfte 4.7-Version außerhalb des Checkouts. Der Prüflauf verwendet ein frisches temporäres Benutzerverzeichnis, importiert das Projekt, startet die Hauptszene und führt alle Suiten mit echter Godot-Physik aus. Skriptfehler führen auch dann zum Fehlschlag, wenn Godot selbst Exitcode 0 liefert; jeder Aufruf hat ein 240-s-Zeitlimit. In Headless-Simulationen werden Audioereignisse und Pools geprüft, aber keine Echtzeit-Playbacks gestartet. Der optionale echte Mixer-Test aktiviert sie ausdrücklich: `godot --headless --audio-driver Dummy --path . --script res://tests/audio_mix_capture.gd -- --audio-headless`. Er schreibt reale Innenraum-/Vakuum-Mischungen nach `/tmp/drift032-*.wav`. `python3 tools/check_audio.py` prüft die ausgelieferten PCM-Dateien, `python3 tools/generate_audio.py` erzeugt sie reproduzierbar neu. Die neue Manöversuite nutzt `--fixed-fps 60` für reproduzierbare, beschleunigt ausgeführte 60-Hz-Simulationsschritte; gemessene Zeiten sind **Simulationszeit**.

[Messwerte und Testergebnisse](docs/validation.md), [Architektur und spätere Schnittstellen](docs/architecture.md).

**Kein interaktiver Desktop-, Hör- oder PlayStation-/Xbox-Hardwaretest für 0.3.2 wurde hier durchgeführt.** Virtuelle Render-Screenshots wurden geprüft; der Nutzer hat zuvor einen erfolgreichen Desktop-Test von 0.1.2 gemeldet. Für diese Version bitte C-Halten/Loslassen, Rückwärtsschub, Retrograde-Abbruch, Instrumente und umbelegte Controller-Kombinationen auf echter Hardware prüfen. Mehrere Controller werden noch nicht getrennten Spielern zugeordnet. Kontakt Alpha ergänzt reale Waffen/Drohne und einen einfachen KI-Gegner; Netzwerk, vollständige Replays und Kampagne bleiben außerhalb des Scopes.

Nächste empfohlene Aufgabe: echte PlayStation-Abnahme von Trigger-Neutralstellung, Stationswechseln, Warnlautstärke und neuem Konsolenablauf; danach Sensor-Sichtlinien und begrenzte Abwehr-Turmschwenkung.

## Grenzen und nächste Schritte (0.2)

Der Innenraum behält seine separate lokale World3D mit künstlicher Schwerkraft. Er bildet Beschleunigungsstürze, Zero-G, Corioliskräfte und physische Kopplung an den globalen Rumpf noch nicht ab. Individuelle Beschleunigungsdaten am nominellen Crewplatz sind vorbereitet; Kollisionsimpulse und künstliche Schwerkraft fließen noch nicht in diese Lastbeobachtung ein. Keine Bewusstlosigkeit oder Gesundheitssimulation. Sensorik ist ein vereinfachter omnidirektionaler Test mit begrenzter Reichweite/Abtastrate/Quantisierung, ohne Sichtlinienprüfung oder reale Signaturphysik. Keine GPU-Performance-Messung; primitive Geometrie und fünf Display-Viewports insgesamt.

Die Innenraum-/Crewplatz-Koordinaten und Stationswege bleiben Kandidaten für weitere Desktop-Abnahme. Hoch-g-Sequenzen mit Beschleunigungsliegen und begrenzter fiktiver Unterstützung sind weiterhin späterer Scope (siehe Architektur).

## Grenzen und nächste Schritte (0.3)

Kontakt Alpha ist eine einzelne Testmission mit einfacher Standoff-/Ausweich-KI, optimistischen omnidirektionalen Sensoren, Szenario-IFF und groben Trefferzonen. Keine Sichtlinien-/Signaturphysik, Gegenmaßnahmen, Explosionen, Treibstoff-Massenänderung oder detaillierten Thruster-Angriffspunkte. Die Raketensucher und Drohnensensoren arbeiten genauer/schneller als die alten Freiflug-Testinstrumente; sie besitzen dennoch Messalter, begrenzte Reichweite und geschätzte Geschwindigkeit. Abwehrgeschütze haben idealisierte Richtmechanik. Gleichzeitige Fehlschüsse, leere Magazine und Treibstoffmangel sind möglich; die Mission erzwingt keinen Sieg durch geskriptete Treffer.

Die getrennte künstliche Innenraum-Schwerkraft aus 0.2 bleibt bestehen. Automatik ist keine versteckte zusätzliche Crew und erhöht keine Schubfreigaben. Noch kein Multiplayer, Replay-Player, Kampagne oder Gesundheitssystem. Als Nächstes: interaktiver Desktop-/Controller-Abnahmetest mit manuellem Abschuss, Rückruf und einem absichtlich ausgewichenen Angriff; anschließend Sensor-Sichtlinien, Trefferortqualität und Abwehr-Balancing verbessern.

## Nächste Abnahme

Manuellen Desktop-/Controller-Test mit Missionswahl, Lock-Aufbau, bewussten Einzelstarts und Rackwechsel durchführen. Danach Abwehr-Turmschwenkung und Sensor-Sichtlinien ergänzen; derzeit schwenkt die Richtmechanik idealisiert, während Reichweite, Beobachtungen, Geschossflug und Vorräte bereits begrenzt sind. Zwei Seeds je Modus/Schwierigkeit sind eine reproduzierbare Stichprobe, keine allgemeine Schwierigkeits- oder Winrate-Garantie.
