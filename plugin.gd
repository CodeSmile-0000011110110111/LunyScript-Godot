@tool
extends EditorPlugin

# Ensures Luny Bootstrap is set as autoload singleton

const LUNY_AUTOLOAD_NAME := "LunyEngineGodotAdapter"
const LUNY_BOOTSTRAP_UID := "uid://ss4vx144dk5g" # LunyEngineGodotAdapter.cs

func _enable_plugin() -> void:
    _ensure_luny_autoload()
    _ensure_analyzer_in_csproj()

func _enter_tree() -> void:
    _ensure_luny_autoload()
    _ensure_analyzer_in_csproj()

func _build() -> bool:
    _ensure_analyzer_in_csproj()
    return true

func _notification(what):
    if what == NOTIFICATION_APPLICATION_FOCUS_IN:
        _ensure_analyzer_in_csproj()


func _remove_luny_autoload() -> void:
    remove_autoload_singleton(LUNY_AUTOLOAD_NAME)
    ProjectSettings.save()

func _disable_plugin() -> void:
    _remove_luny_autoload()


func _ensure_luny_autoload() -> void:
    var res_path := ResourceUID.uid_to_path(LUNY_BOOTSTRAP_UID)
    add_autoload_singleton(LUNY_AUTOLOAD_NAME, res_path)
    ProjectSettings.save()


func _ensure_analyzer_in_csproj() -> void:
    var path = _get_csproj_path()
    if path == "":
        return
        
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return
        
    var content = file.get_as_text()
    file.close()
    
    var analyzer_path = "addons/lunyscript/LunyScript/Analyzers/LunyScript-Analyzers.dll"
    # Normalize slashes for comparison to avoid duplicates if different slashes are used
    var check_path = analyzer_path.replace("\\", "/")
    var normalized_content = content.replace("\\", "/")
    
    if normalized_content.contains("<Analyzer Include=\"" + check_path + "\""):
        return
        
    # Insert before </Project>
    var insert_pos = content.find("</Project>")
    if insert_pos == -1:
        return
        
    var block = "\n  <ItemGroup>\n    <Analyzer Include=\"" + analyzer_path + "\" />\n  </ItemGroup>\n"
    var new_content = content.insert(insert_pos, block)
    
    file = FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(new_content)
        file.close()


func _get_csproj_path() -> String:
    var assembly_name = ProjectSettings.get_setting("dotnet/project/assembly_name", "")
    if assembly_name == "":
        assembly_name = ProjectSettings.get_setting("application/config/name", "")

    var path = "res://" + assembly_name + ".csproj"
    if FileAccess.file_exists(path):
        return path

    # TODO: Fallback for multiple .csproj

    return ""
