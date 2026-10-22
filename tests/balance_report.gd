extends SceneTree

var rows: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
 for mode in range(3):
  for difficulty in range(3):
   for seed_value in [1741,71]:
    rows.append(await BalanceScenario.battle(self, mode,difficulty,seed_value))
 for plan in ["no-drone","guard","bad-position","lateral"]:
  for seed_value in [1741,71]: rows.append(await BalanceScenario.battle(self, CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,seed_value,plan))
 var file:=FileAccess.open("res://docs/balance-0.3.1.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(rows,"  ")+"\n")
 quit()
