class_name CombatDisplay
extends TacticalDisplay

var encounter: CombatEncounter

func _draw() -> void:
 if encounter==null:
  super._draw()
  return
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.027,0.033))
 draw_rect(Rect2(6,6,948,628),Color(0.25,0.4,0.43),false,3)
 line(38,"KONTAKT ALPHA / "+("MISSILE CONTROL" if weapons else "DEFENSE DRONE"))
 line(68,"%.1f s | %s | SENSOR AGE / QUALITY MATTER"%[encounter.elapsed,encounter.result],Color(0.45,0.64,0.7),32,19)
 var center := Vector2(250,263)
 for radius: float in [55,110,165]: draw_arc(center,radius,0,TAU,64,Color(0.15,0.3,0.35))
 draw_line(center-Vector2(175,0),center+Vector2(175,0),Color(0.2,0.4,0.45))
 draw_line(center-Vector2(0,175),center+Vector2(0,175),Color(0.2,0.4,0.45))
 draw_colored_polygon(PackedVector2Array([center+Vector2(0,-10),center+Vector2(-6,6),center+Vector2(6,6)]),Color(0.3,0.65,0.95))
 line(95,"FORWARD -Z / 2.5 km",Color(0.3,0.65,0.95),75,19)
 for contact in sensors.contacts:
  var point := center+Vector2(contact.relative_position.x,contact.relative_position.z)/2500*165
  var color := Color(0.9,0.4,0.2) if contact.team==1 else Color(0.3,0.85,0.55)
  draw_circle(point,4 if contact.kind=="missile" else 6,color)
  if contact.contact_id==sensors.selected_id: draw_arc(point,11,0,TAU,24,Color.WHITE,2)
  draw_string(font,point+Vector2(10,-8),contact.contact_id,HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
 var selected := sensors.selected()
 if selected!=null:
  line(130,"> "+selected.contact_id+" / "+selected.kind,Color(0.9,0.6,0.28),470,23)
  line(160,"%.0f m / Q %.0f%% / AGE %.1f s"%[selected.relative_position.length(),selected.quality*100,selected.age_seconds],Color(0.72,0.82,0.8),470,20)
  line(188,"TRACK %s / v %s"%[selected.tracking,str(selected.relative_velocity.snapped(Vector3.ONE))],Color(0.6,0.75,0.75),470,18)
 else: line(130,"NO SENSOR CONTACT",Color(0.9,0.6,0.28),470,23)
 if weapons:
  var launcher := encounter.player_launcher
  for i in range(2):
   line(230+i*30,"%s %s RACK / %d MISSILES"%[">" if i==launcher.selected_launcher else " ","PORT" if i==0 else "STBD",launcher.ammunition[i]],Color(0.65,0.85,0.8),470,22)
  line(300,"ARMED" if launcher.armed else "SAFE",Color(0.95,0.6,0.2),470,24)
  line(330,launcher.last_status,Color(0.8,0.8,0.7),470,20)
  var y: float = 367
  for missile in encounter.missiles:
   if is_instance_valid(missile) and missile.team==0 and y<435:
    line(y,"%s %s dv %.0f"%[missile.name,missile.status,missile.fuel_delta_v],Color(0.65,0.8,0.75),470,17)
    y+=23
  line(435,"FC ~%.1f s / 300 m/s model"%fire_control.solution_seconds if fire_control.solution_valid else "FC / TRACK REQUIRED",Color(0.45,0.65,0.7),470,18)
 else:
  if is_instance_valid(encounter.drone):
   var drone := encounter.drone
   line(230,"BLUE-D1 / "+drone.status,Color(0.3,0.85,0.55),470,21)
   line(260,"PD %s / rounds %d"%["ON" if drone.defense_enabled else "OFF",drone.ammunition],Color(0.7,0.8,0.75),470,22)
   line(290,"Fuel dv %.0f m/s"%drone.fuel_delta_v,Color(0.7,0.8,0.75),470,22)
   # Own drone telemetry is a cooperative radio link, not target ground truth.
   var relative := encounter.player.global_basis.inverse()*(drone.global_position-encounter.player.global_position)
   line(320,"Relative XYZ %s m"%str(relative.snapped(Vector3.ONE)),Color(0.7,0.8,0.75),470,18)
   line(350,"Waypoint %d / %.0f m"%[encounter.selected_waypoint+1,drone.waypoint.length()],Color(0.7,0.8,0.75),470,20)
  else:
   line(240,"BLUE-D1 / "+("DOCKED" if encounter.drone_available else "LOST"),Color(0.3,0.85,0.55),470,24)
   line(275,"Reserve %d rounds / dv %.0f"%[encounter.drone_rounds,encounter.drone_fuel],Color(0.7,0.8,0.75),470,20)
 var damage := encounter.player.damage_model
 line(458,"HULL %.0f | ENG %.0f | RCS %.0f | SENS %.0f | WPN %.0f"%[damage.health.hull,damage.health.main,damage.health.rcs,damage.health.sensors,damage.health.weapons],Color(0.88,0.64,0.35),32,21)
 line(490,"AUTO %s (unoccupied only) | %s"%[encounter.automatic_weapons if weapons else encounter.automatic_drone,encounter.last_message.left(48)],Color(0.65,0.8,0.75),32,19)
 line(525,"←/→ D-pad: target | T/X: track | F/A: leave | U/B: harness",Color(0.7,0.78,0.78),32,19)
 if weapons:
  line(560,"L / D-pad UP: rack | K / D-pad DOWN: arm/safe",Color(0.8,0.86,0.8),32,22)
  line(593,"R/RB: FIRE | H/LB: missile cam | O/RS: auto",Color(0.95,0.6,0.25),32,22)
 else:
  line(560,"L/UP: deploy | K/DOWN: waypoint | H/LB: world hold",Color(0.8,0.86,0.8),32,21)
  line(593,"R/RB: defense | C/Back: recall | O/RS: automation",Color(0.45,0.9,0.65),32,21)
 line(622,"Pad labels: Xbox / PS: A=Cross B=Circle X=Square RB=R1 LB=L1",Color(0.4,0.58,0.6),32,17)
