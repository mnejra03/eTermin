Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
folder = fileSystem.GetParentFolderName(WScript.ScriptFullName)
script = folder & "\Start-eTermin.ps1"
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & script & """", 0, False
