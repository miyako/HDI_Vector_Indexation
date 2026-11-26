// Follow the OS language so the XLIFF resources (en, ja) resolve before any
// UI is displayed. See the 4dlocalise skill.
var $language : Text
$language:=Get database localization(User system localization)
SET DATABASE LOCALIZATION(($language="ja@") ? "ja" : "en")

00_Start 
