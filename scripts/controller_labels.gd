class_name ControllerLabels
extends RefCounted

# Godot logical button indices, identical to the Input Map. No glyph-font asset.
static func detect(name: String) -> int:
 var value:=name.to_lower()
 if ["playstation","dualshock","dualsense","sony","ps4","ps5"].any(func(s: String) -> bool: return value.contains(s)): return 1
 if value.contains("xbox") or value.contains("xinput"): return 2
 return 0

static func button(index: int, scheme: int) -> String:
 var ps: Array[String]=["✕","Kreis","Quadrat","Dreieck","Share/Create","PS","Options","L3","R3","L1","R1","Steuerkreuz ↑","Steuerkreuz ↓","Steuerkreuz ←","Steuerkreuz →"]
 var xbox: Array[String]=["A","B","X","Y","View","Guide","Menu","LS","RS","LB","RB","D-pad ↑","D-pad ↓","D-pad ←","D-pad →"]
 var names:=ps if scheme==1 else xbox
 return names[index] if index>=0 and index<names.size() else "Button %d"%index

static func adapt(value: String, scheme: int) -> String:
 if scheme==0: return value
 var replacements: Dictionary
 if scheme==1:
  value=value.replace("A/Cross","✕").replace("B/Circle","Kreis").replace("X/Square","Quadrat").replace("LS-click","L3").replace("RS to orbit","rechter Stick to orbit")
  replacements={"A / Cross":"✕","B / Circle":"Kreis","X / Square":"Quadrat","Y / Triangle":"Dreieck","Start / Options":"Options","RT/R2":"R2","LT/L2":"L2","LB/L1":"L1","RB/R1":"R1","RS click":"R3","LS click":"L3","D-pad":"Steuerkreuz","LS:":"Linker Stick:","RS:":"Rechter Stick:"}
 else:
  replacements={"A / Cross":"A","B / Circle":"B","X / Square":"X","Y / Triangle":"Y","Start / Options":"Menu","RT/R2":"RT","LT/L2":"LT","LB/L1":"LB","RB/R1":"RB"}
 for key: String in replacements: value=value.replace(key,replacements[key])
 return value
