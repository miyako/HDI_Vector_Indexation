// Method: BuildData
// Headless rebuild of the demo data (see the demo-vector-search skill):
// 1. drop existing records
// 2. import the corpus (train.txt) in batches, embedding each batch with the
//    document prefix; the same vector is stored in IndexedVector (indexed by
//    the vector index) and NonIndexedVector (no index) for the comparison
// 3. create the vector index (cosine) on Data.IndexedVector
// 4. create the bilingual sample prompts, each with its embedded query vector
// 5. stop the embedding server only if this run started it, then quit
//
// --user-param='{"limit":N}' imports only the first N lines (testing).

#DECLARE($params : Object)

ON ERR CALL("build_on_err")

var $paramText : Text:=""
var $limit : Integer:=0
If (Get database parameter(User param value; $paramText)=0) && ($paramText#"")
	var $config : Object:=JSON Parse($paramText)
	$limit:=$config.limit
End if 
var $report : Text:="BuildData start "+String(Current time)+" limit="+String($limit)+"\n"

// ---------- embedding model ----------
var $model : cs.EmbeddingModel:=cs.EmbeddingModel.new(18083; "ruri-v3-310m"; "検索クエリ: "; "検索文書: "; 128)
$model.start()
$report+="model ready: "+String(Current time)+"\n"
LOG EVENT(Into system standard outputs; $report)

// ---------- corpus ----------
var $corpusFile : 4D.File:=Folder(fk resources folder).file("train.txt")
If (Not($corpusFile.exists))
	LOG EVENT(Into system standard outputs; "FATAL missing corpus "+$corpusFile.path)
	File("/PACKAGE/build.FAILED").setText("missing corpus")
	QUIT 4D(1)
End if 

var $lines : Collection:=New collection()
var $raw : Text:=$corpusFile.getText()
var $part : Text
For each ($part; Split string($raw; Char(Line feed)))
	If ($part#"")
		$lines.push(Replace string($part; Char(Carriage return); ""))
	End if 
End for each 
$raw:=""
If ($limit>0)
	$lines:=$lines.slice(0; $limit)
End if 
var $lineCount : Integer:=$lines.length
$report+="corpus lines: "+String($lineCount)+"\n"
LOG EVENT(Into system standard outputs; $report)

// ---------- import ----------
var $start : Integer:=Current time
ds.Data.all().drop()

var $batchStart : Integer
For ($batchStart; 1; $lineCount; 128)
	var $last : Integer:=$batchStart+127
	If ($last>$lineCount)
		$last:=$lineCount
	End if 
	var $batchLines : Collection:=New collection()
	var $i : Integer
	For ($i; $batchStart; $last)
		$batchLines.push($lines[$i-1])
	End for 
	var $vectors : Collection:=$model.embedDocuments($batchLines)
	var $vectorCount : Integer:=$vectors.length
	For ($i; 1; $vectorCount)
		var $entity : cs.DataEntity:=ds.Data.new()
		$entity.Text:=$batchLines[$i-1]
		$entity.IndexedVector:=$vectors[$i-1]
		$entity.NonIndexedVector:=$vectors[$i-1]
		$entity.EmbeddingModel:=$model.modelName
		$entity.save()
	End for 
End for 

$report+="imported "+String(ds.Data.all().length)+" rows in "+String(Current time-$start)+"\n"
LOG EVENT(Into system standard outputs; $report)

// ---------- vector index ----------
$start:=Current time
ARRAY POINTER($fields; 1)
$fields{1}:=->[Data]IndexedVector
CREATE INDEX([Data]; $fields; Vector cosine index; "IndexedVector_cosine")
$report+="index built in "+String(Current time-$start)+"\n"

// ---------- prompts (bilingual) ----------
var $prompts : Collection:=[{en: "What local groups can help?"; ja: "地域で利用できる支援団体はありますか？"}; {en: "How does the human mind work?"; ja: "人間の心はどのように働くのですか？"}; {en: "Where did this happen?"; ja: "これはどこで起きたことですか？"}; {en: "Why do we love makeup?"; ja: "なぜ人は化粧が好きなのでしょう？"}; {en: "How Can I Deal with Opposing Opinions of Family and Friends?"; ja: "家族や友人と意見が対立したとき、どう向き合えばいいですか？"}; {en: "Does any one have any ideas on this?"; ja: "これについて何か良いアイデアはありますか？"}]

var $enTexts : Collection:=New collection()
var $jaTexts : Collection:=New collection()
var $p : Integer
ds.Prompts.all().drop()
For ($p; 1; $prompts.length)
	$enTexts.push($prompts[$p-1].en)
	$jaTexts.push($prompts[$p-1].ja)
End for 
var $enVectors : Collection:=$model.embedDocuments($enTexts)
var $jaVectors : Collection:=$model.embedDocuments($jaTexts)

For ($p; 1; $prompts.length)
	var $prompt : cs.PromptsEntity:=ds.Prompts.new()
	$prompt.PromptEN:=$prompts[$p-1].en
	$prompt.PromptJA:=$prompts[$p-1].ja
	$prompt.VectorEN:=$enVectors[$p-1]
	$prompt.VectorJA:=$jaVectors[$p-1]
	$prompt.EmbeddingModel:=$model.modelName
	$prompt.save()
End for 

$report+="prompts: "+String($prompts.length)+"\n"
$report+="counts: Data "+String(ds.Data.all().length)+" Prompts "+String(ds.Prompts.all().length)+"\n"
$report+="BuildData done "+String(Current time)+"\n"
LOG EVENT(Into system standard outputs; $report)

File("/PACKAGE/build.report").setText($report)

$model.stop()
QUIT 4D(0)
