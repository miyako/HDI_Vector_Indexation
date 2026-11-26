//%attributes = {"invisible":true}
// InitInfoPageHTML: returns the help page HTML for the current UI language,
// falling back to the English resource when the localized file is missing.

#DECLARE($page : Integer)->$html : Text

var $name : Text:="info"+String($page)+".html"
var $path : Text:=Localized document path($name)
var $file : 4D.File

If ($path#"")
	$file:=File($path; fk platform path)
End if 

If (($file#Null) && $file.exists)
	$html:=$file.getText()
Else 
	$file:=Folder(fk resources folder).file("en.lproj/"+$name)
	If ($file.exists)
		$html:=$file.getText()
	End if 
End if 
