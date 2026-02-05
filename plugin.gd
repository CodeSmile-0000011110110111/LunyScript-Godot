@tool
extends EditorPlugin

# usings
const File = Gds.File
const Str = Gds.Str
const Res = Gds.Res
const Project = GdsEditor.Project

const LunyEngineAutoloadName := "LunyEngineGodotAdapter"
const LunyGodotAdapterUid := "uid://ss4vx144dk5g" # ../lunyscript/Luny.Godot/Engine/LunyEngineGodotAdapter.cs
const LunyScriptAnalyzerPath = "addons/lunyscript/LunyScript/Analyzers/LunyScript-Analyzers.dll" # for .csproj


func AddLunyEngineAutoload() -> void:
    var resPath := Res.UidToPath(LunyGodotAdapterUid)
    Project.AddAutoloadSingleton(self, LunyEngineAutoloadName, resPath)
    Project.Save()


func RemoveLunyEngineAutoload() -> void:
    Project.RemoveAutoloadSingleton(self, LunyEngineAutoloadName)
    Project.Save()


func EnsureAnalyzerReferencedInCsproj() -> void:
    var path = GetCsprojPath()
    if path == "":
        return
        
    var file = File.OpenReadable(path)
    if not file:
        return
        
    var content = File.ReadAllText(file)
    File.Close(file)
    
    # Normalize slashes for comparison to avoid duplicates if different slashes are used
    var checkPath = Str.Replace(LunyScriptAnalyzerPath, "\\", "/")
    var normalizedContent = Str.Replace(content, "\\", "/")

    var analyzerInclude = "<Analyzer Include=\"" + checkPath + "\""
    if Str.Contains(normalizedContent, analyzerInclude):
        return
        
    # Insert before </Project>
    var insertPos = Str.Find(content, "</Project>")
    if insertPos == -1:
        return
        
    var block = "\n  <ItemGroup>\n    " + analyzerInclude + " />\n  </ItemGroup>\n"
    var newContent = Str.Insert(content, insertPos, block)
    
    file = File.OpenWritable(path)
    if file:
        File.WriteAllText(file, newContent)
        File.Close(file)


func GetCsprojPath() -> String:
    var assemblyName = Project.GetSetting("dotnet/project/assembly_name", "")
    if assemblyName == "":
        assemblyName = Project.GetSetting("application/config/name", "")

    var path = "res://" + assemblyName + ".csproj"
    if File.Exists(path):
        return path

    # TODO: Fallback for multiple .csproj

    return ""


## GDScript Signals ...
func _enable_plugin() -> void:
    AddLunyEngineAutoload()
    EnsureAnalyzerReferencedInCsproj()

func _disable_plugin() -> void:
    RemoveLunyEngineAutoload()

func _enter_tree() -> void:
    AddLunyEngineAutoload()
    EnsureAnalyzerReferencedInCsproj()

func _build() -> bool:
    EnsureAnalyzerReferencedInCsproj()
    return true

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_IN:
        EnsureAnalyzerReferencedInCsproj()
