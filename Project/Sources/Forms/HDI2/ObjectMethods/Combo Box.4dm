//%attributes = {}
// Combo Box: the prompt selection changed; update the current prompt entity
// and its query vector.

If (FORM Event.code=On Data Change)
	
	var $isJa : Boolean:=(Get database localization(User system localization)="ja@")
	var $index : Integer:=Form.questions.values.indexOf(Form.questions.currentValue)
	
	If ($index>=0)
		Form.currentQuestion:=Form.prompts[$index]
		Form.currentVector:=($isJa ? Form.currentQuestion.VectorJA : Form.currentQuestion.VectorEN)
	End if 
	
End if 
