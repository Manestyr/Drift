class_name CombatProfile
extends RefCounted

enum Mode { MANUAL, ASSISTED_SOLO, FULL_AUTO }
enum Difficulty { EASY, NORMAL, HARD }
const MODE_NAMES: Array[String] = ["MANUAL","ASSISTED SOLO","FULL AUTO / DEMO"]
const DIFFICULTY_NAMES: Array[String] = ["EASY","NORMAL","HARD"]

static func settings(difficulty: int) -> Dictionary:
 return [
  {"reaction":1.3,"interval":18.0,"first":14.0,"cadence":0.75,"precision":1.0,"weave":0.12,"defense_time":23.0,"rounds":2,"gun_delay":0.65},
  {"reaction":0.7,"interval":13.0,"first":11.0,"cadence":0.4,"precision":0.5,"weave":0.24,"defense_time":5.0,"rounds":10,"gun_delay":0.4},
  {"reaction":0.35,"interval":10.0,"first":8.0,"cadence":0.2,"precision":0.25,"weave":0.34,"defense_time":3.0,"rounds":18,"gun_delay":0.3}
 ][clampi(difficulty,0,2)].duplicate()
