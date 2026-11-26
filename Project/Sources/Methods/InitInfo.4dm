//%attributes = {"invisible":true}
// InitInfo: create or refresh the INFO help records in the current UI language.
// The page HTML lives in Resources/<lang>.lproj/info<N>.html and the tab
// titles are XLIFF IDs (Info_Tab<N>). Refreshing on every launch keeps the
// help text in step with the UI language, whatever data file ships with the
// demo.

var $page : Integer

For ($page; 1; 2)
	var $html : Text:=InitInfoPageHTML($page)
	If ($html="")
		continue
	End if 
	
	var $entity : cs.INFOEntity:=ds.INFO.query("PageNumber=:1"; $page).first()
	If ($entity=Null)
		$entity:=ds.INFO.new()
		$entity.PageNumber:=$page
	End if 
	
	$entity.TabTitle:=Localized string("Info_Tab"+String($page))
	$entity.Description:=$html
	$entity.save()
	
End for 

// Load all INFO records ordered by page number
Form.Infos:=ds.INFO.all().orderBy("PageNumber").toCollection()

// Create tabs object with extracted titles
Form.objTabs:=New object("values"; Form.Infos.extract("TabTitle"); "index"; 0)
