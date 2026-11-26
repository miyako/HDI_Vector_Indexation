//%attributes = {}
// Init: build the prompt list in the current UI language and select the first
// prompt. Prompts are stored in both languages (PromptEN/PromptJA) with their
// query vectors (VectorEN/VectorJA); the search runs with the vector that
// matches the language the user is running.

var $isJa : Boolean:=(Get database localization(User system localization)="ja@")
var $prompts : Collection:=ds.Prompts.all().orderBy("ID").toCollection()

var $labels : Collection:=New collection()
var $prompt : Object
For each ($prompt; $prompts)
	$labels.push(($isJa ? $prompt.PromptJA : $prompt.PromptEN))
End for each 

Form.prompts:=$prompts
Form.questions:={values: $labels; currentValue: $labels[0]}
Form.currentQuestion:=$prompts[0]
Form.currentVector:=($isJa ? $prompts[0].VectorJA : $prompts[0].VectorEN)
