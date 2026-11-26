//%attributes = {}
// Method: 00_Start
// Description: Opens the demo window. Called with no parameter by the
// On Startup database method and the Demo menu item; re-enters itself in
// the application process through CALL WORKER (see the 4dstartup skill).

#DECLARE($params : Object)

var $window : Integer
var $title : Text
$title:=Localized string("HDI2_WindowTitle")

If (Count parameters=0)
	
	// already open? bring it to the front instead of opening a duplicate
	ARRAY LONGINT($windows; 0)
	WINDOW LIST($windows)
	var $i : Integer
	For ($i; 1; Size of array($windows))
		$window:=$windows{$i}
		If (Window process($window)=1) && (Get window title($window)=$title)
			var $left; $top; $right; $bottom : Integer
			GET WINDOW RECT($left; $top; $right; $bottom; $window)
			CALL FORM($window; Formula(SET WINDOW RECT($left; $top; $right; $bottom; $window)))
			return 
		End if 
	End for 
	
	CALL WORKER(1; Current method name; {})
	
Else 
	
	SET MENU BAR(1)
	$window:=Open form window("HDI2"; Plain form window; Horizontally centered; Vertically centered)
	SET WINDOW TITLE($title; $window)
	DIALOG("HDI2"; $params; *)
	
End if 
