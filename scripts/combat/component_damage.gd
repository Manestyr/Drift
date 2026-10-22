class_name ComponentDamage
extends RefCounted

signal system_damaged(system: String, remaining: float)
var health: Dictionary = {"hull":100.0,"main":100.0,"rcs":100.0,"sensors":100.0,"weapons":100.0}

func efficiency(system: String) -> float:
 return clampf(float(health.get(system,0.0))/100.0,0.0,1.0)

func incapable() -> bool:
 return health.hull <= 0.0 or health.weapons <= 0.0 or (health.main <= 0.0 and health.rcs <= 0.0)

func zone(local_point: Vector3) -> String:
 if local_point.z > 8.0: return "main"
 if absf(local_point.x)>2.2: return "rcs"
 if local_point.z < -8.0: return "weapons"
 if local_point.y > 1.0: return "sensors"
 return "hull"

func hit(local_point: Vector3, strength: float = 34.0) -> String:
 var system := zone(local_point)
 damage("hull",strength)
 if system != "hull": damage(system,strength*1.5)
 return system

func damage(system: String, amount: float) -> void:
 if not health.has(system): return
 health[system] = maxf(0.0,float(health[system])-maxf(0.0,amount))
 system_damaged.emit(system,health[system])
