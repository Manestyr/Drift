class_name CombatEvents
extends RefCounted

signal recorded(event: Dictionary)
var entries: Array[Dictionary] = []
var sequence: int = 0

func record(tick: int, type: String, entity_id: String, payload: Dictionary = {}) -> void:
 sequence += 1
 var event := {"tick":tick,"sequence":sequence,"type":type,"entity_id":entity_id,"payload":payload.duplicate(true)}
 entries.append(event)
 recorded.emit(event)
