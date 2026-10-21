extends SceneTree

var failures: int = 0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 if ok:
  print("PASS: ", message)
 else:
  failures += 1
  push_error("FAIL: " + message)

func ticks(count: int) -> void:
 for i in range(count):
  await physics_frame
 await process_frame

func run() -> void:
 var ship := ShipPhysics.new()
 root.add_child(ship)
 ship.linear_velocity = Vector3(12, -3, 7)
 await ticks(10)
 var initial := ship.linear_velocity
 await ticks(120)
 check(ship.linear_velocity.distance_to(initial) < 0.001, "120 ticks coasting preserves world velocity")
 ship.reset_requested = true
 await ticks(3)
 ship.command.main_engine = 1.0
 var start_tick := ship.tick
 var before := ship.linear_velocity
 await ticks(120)
 var elapsed := float(ship.tick - start_tick) / 60.0
 var expected := Vector3.FORWARD * ship.main_thrust_n / ship.mass * elapsed
 check((ship.linear_velocity - before).distance_to(expected) < 0.4, "main thrust matches F/m integrated over actual fixed ticks")
 check(absf(ship.acceleration_world.length() - 20.0) < 0.001, "proper acceleration is 20 m/s²")
 ship.command.clear()
 await ticks(3)
 initial = ship.linear_velocity
 var initial_basis := ship.basis
 ship.command.rotation.y = 0.5
 await ticks(120)
 check(ship.basis.z.distance_to(initial_basis.z) > 0.1, "torque actually rotates rigid body")
 check(ship.linear_velocity.distance_to(initial) < 0.001, "rotation preserves linear world velocity")
 ship.command.clear()
 await ticks(3)
 var angular := ship.angular_velocity
 await ticks(60)
 check(ship.angular_velocity.distance_to(angular) < 0.001, "no angular damping after torque release")
 ship.reset_requested = true
 await ticks(3)
 check(ship.position.length() < 0.001 and ship.linear_velocity.length() < 0.001 and ship.angular_velocity.length() < 0.001, "reset clears position and both velocities")
 ship.queue_free()
 print("Flight checks complete; failures=", failures)
 quit(1 if failures else 0)
