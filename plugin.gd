@tool
extends EditorPlugin

# usings
const File = Gds.File
const Str = Gds.Str
const Res = Gds.Res
const Project = GdsEditor.Project

const LunyEngineAutoloadName := "LunyEngineGodotAdapter"
const LunyGodotAdapterUid := "uid://ss4vx144dk5g" # UID of LunyEngineGodotAdapter.cs
const AnalyzerPath = "addons/lunyscript/LunyScript/Analyzers/LunyScript-Analyzers.dll"

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
    var checkPath = Str.Replace(AnalyzerPath, "\\", "/")
    var normalizedContent = Str.Replace(content, "\\", "/")
    
    if Str.Contains(normalizedContent, "<Analyzer Include=\"" + checkPath + "\""):
        return
        
    # Insert before </Project>
    var insertPos = Str.Find(content, "</Project>")
    if insertPos == -1:
        return
        
    var block = "\n  <ItemGroup>\n    <Analyzer Include=\"" + AnalyzerPath + "\" />\n  </ItemGroup>\n"
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


## Wrapped Signals ...
func OnEnablePlugin() -> void:
    AddLunyEngineAutoload()
    EnsureAnalyzerReferencedInCsproj()

func OnDisablePlugin() -> void:
    RemoveLunyEngineAutoload()

func OnEnterTree() -> void:
    AddLunyEngineAutoload()
    EnsureAnalyzerReferencedInCsproj()

func OnBuild() -> void:
    EnsureAnalyzerReferencedInCsproj()

func OnEditorReceiveFocus() -> void:
    EnsureAnalyzerReferencedInCsproj()


## GDScript Signals ...
func _enable_plugin() -> void:
    OnEnablePlugin()

func _disable_plugin() -> void:
    OnDisablePlugin()

func _enter_tree() -> void:
    OnEnterTree()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_IN:
        OnEditorReceiveFocus()

func _build() -> bool:
    OnBuild()
    return true
