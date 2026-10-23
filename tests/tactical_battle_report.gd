extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var rows: Array[Dictionary]=[]
 for seed_value in [71,1741]:
  for plan: String in ["no-drone","guard","bad-position"]:
   rows.append(await BalanceScenario.battle(self,CombatProfile.Mode.MANUAL,CombatProfile.Difficulty.NORMAL,seed_value,plan))
 var output:=FileAccess.open("res://docs/tactical-battles-0.3.3.json",FileAccess.WRITE)
 output.store_string(JSON.stringify(rows," ")+"\n")
 quit()
