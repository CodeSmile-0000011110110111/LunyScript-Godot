extends Node

# Ensures GodotLifecycleAdapter gets instantiated when launching player

const GODOT_LIFECYCLE_ADAPTER_CS := preload("uid://ss4vx144dk5g")

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        return  # runtime only

    # Instantiate the C# adapter directly and add to the scene root
    #var adapter := GodotLifecycleAdapter.new()
    var adapter := GODOT_LIFECYCLE_ADAPTER_CS.new() # creates instance of the C# class
    if adapter:
        get_tree().root.add_child.call_deferred(adapter)
        queue_free() # bootstrap no longer needed after spawning adapter
    else:
        push_error("Failed to instantiate Luny.Godot.GodotLifecycleAdapter")
