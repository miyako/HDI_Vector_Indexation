//%attributes = {}
Case of 
		
	: (FORM Event.code=On Load)
		
		InitInfo
		Init
		
	: (FORM Event.code=On Close Box)
		
		// return to design mode instead of quitting the process
		CANCEL
		
End case 
