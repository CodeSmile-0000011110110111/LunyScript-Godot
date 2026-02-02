@tool
extends EditorPlugin

# Ensures Luny Bootstrap is set as autoload singleton

const LunyAutoloadName := "LunyEngineGodotAdapter"
const LunyBootstrapUid := "uid://ss4vx144dk5g" # LunyEngineGodotAdapter.cs
const AnalyzerPath = "addons/lunyscript/LunyScript/Analyzers/LunyScript-Analyzers.dll"

func OnEnablePlugin() -> void:
    EnsureLunyAutoload()
    EnsureAnalyzerInCsproj()

func OnDisablePlugin() -> void:
    RemoveLunyAutoload()

func OnEnterTree() -> void:
    EnsureLunyAutoload()
    EnsureAnalyzerInCsproj()

func OnBuild() -> void:
    EnsureAnalyzerInCsproj()

func OnEditorReceiveFocus() -> void:
    EnsureAnalyzerInCsproj()

func RemoveLunyAutoload() -> void:
    RemoveAutoloadSingleton(LunyAutoloadName)
    SaveProjectSettings()

func EnsureLunyAutoload() -> void:
    var resPath := UidToPath(LunyBootstrapUid)
    AddAutoloadSingleton(LunyAutoloadName, resPath)
    SaveProjectSettings()

func EnsureAnalyzerInCsproj() -> void:
    var path = GetCsprojPath()
    if path == "":
        return
        
    var file = FileOpenRead(path)
    if not file:
        return
        
    var content = FileReadAllText(file)
    FileClose(file)
    
    # Normalize slashes for comparison to avoid duplicates if different slashes are used
    var checkPath = StringReplace(AnalyzerPath, "\\", "/")
    var normalizedContent = StringReplace(content, "\\", "/")
    
    if StringContains(normalizedContent, "<Analyzer Include=\"" + checkPath + "\""):
        return
        
    # Insert before </Project>
    var insertPos = StringFind(content, "</Project>")
    if insertPos == -1:
        return
        
    var block = "\n  <ItemGroup>\n    <Analyzer Include=\"" + AnalyzerPath + "\" />\n  </ItemGroup>\n"
    var newContent = StringInsert(content, insertPos, block)
    
    file = FileOpenWrite(path)
    if file:
        FileWriteAllText(file, newContent)
        FileClose(file)

func GetCsprojPath() -> String:
    var assemblyName = GetProjectSetting("dotnet/project/assembly_name", "")
    if assemblyName == "":
        assemblyName = GetProjectSetting("application/config/name", "")

    var path = "res://" + assemblyName + ".csproj"
    if FileExists(path):
        return path

    # TODO: Fallback for multiple .csproj

    return ""


## GDScript native wrappers ...

# SIGNALS
func _enable_plugin() -> void:
    OnEnablePlugin()

func _disable_plugin() -> void:
    OnDisablePlugin()

func _enter_tree() -> void:
    OnEnterTree()

func _build() -> bool:
    OnBuild()
    return true

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_IN:
        OnEditorReceiveFocus()

# File
func FileExists(path: String) -> bool:
    return FileAccess.file_exists(path)

func FileOpen(path: String, flags: FileAccess.ModeFlags) -> FileAccess:
    return FileAccess.open(path, flags)

func FileOpenRead(path: String) -> FileAccess:
    return FileOpen(path, FileAccess.READ)

func FileOpenWrite(path: String) -> FileAccess:
    return FileOpen(path, FileAccess.WRITE)

func FileClose(file: FileAccess) -> void:
    file.close()

func FileReadAllText(file: FileAccess) -> String:
    return file.get_as_text()

func FileWriteAllText(file: FileAccess, text: String) -> void:
    file.store_string(text)

# String
func StringReplace(text: String, what: String, forWhat: String) -> String:
    return text.replace(what, forWhat)

func StringContains(text: String, what: String) -> bool:
    return text.contains(what)

func StringFind(text: String, what: String) -> int:
    return text.find(what)

func StringInsert(text: String, pos: int, what: String) -> String:
    return text.insert(pos, what)

# Editor
func GetProjectSetting(name: String, defaultValue: Variant) -> Variant:
    return ProjectSettings.get_setting(name, defaultValue)

func SaveProjectSettings() -> void:
    ProjectSettings.save()

func UidToPath(uid: String) -> String:
    return ResourceUID.uid_to_path(uid)

func AddAutoloadSingleton(name: String, path: String) -> void:
    add_autoload_singleton(name, path)

func RemoveAutoloadSingleton(name: String) -> void:
    remove_autoload_singleton(name)
