// Class: EmbeddingModel
// Wraps a local llama-server embedding endpoint (see the 4dembeddings skill).
// The server is started through the llama-cpp component; embeddings are read
// through 4D AI Kit's OpenAI-compatible client. No API key is needed.
//
// Note: scalar Min/Max throw a recoverable error 59 in the 21 R5 interpreter,
// so bounds are computed with If/Else here (see the 4dlang skill).

property port : Integer
property modelName : Text
property queryPrefix : Text
property documentPrefix : Text
property batchSize : Integer
property startedHere : Boolean

var $client : Object    // cs.AIKit.OpenAI
var $llama : Object     // cs.llama.llama handle for terminate()

// Class constructor($port; $modelName; $queryPrefix; $documentPrefix; $batchSize)
Class constructor
	
	This.port:=$1
	This.modelName:=$2
	This.queryPrefix:=$3
	This.documentPrefix:=$4
	This.batchSize:=$5
	This.startedHere:=False
	

Function isReady()->$ready : Boolean
	
	var $request : 4D.HTTPRequest:=4D.HTTPRequest.new("http://127.0.0.1:"+String(This.port)+"/health"; {method: "GET"})
	var $response : Object:=$request.wait()
	// 4D.HTTPRequest.wait() returns the request object; the HTTP response is
	// nested under .response (status, headers, body).
	$ready:=($response.response.status=200)
	

Function start()
	
	If (This.isReady())
		This.startedHere:=False
		LOG EVENT(Into system standard outputs; "llama-server already running on port "+String(This.port))
	Else 
		
		var $home : 4D.Folder:=Folder(fk home folder).folder(".GGUF")
		var $modelFile : 4D.File:=$home.folder("ruri-v3-310m-GGUF").file("ruri-v3-310m-q8_0.gguf")
		If (Not($modelFile.exists))
			LOG EVENT(Into system standard outputs; "FATAL model file missing: "+$modelFile.path)
			return 
		End if 
		
		var $options : Object
		$options:={model: $modelFile; embeddings: True; pooling: "mean"; ctx_size: 8192; batch_size: 8192; ubatch_size: 8192; n_gpu_layers: -1; log_disable: True}
		
		var $event : cs.event.event
		$event:=cs.event.event.new()
		$event.onError:=Formula(LOG EVENT(Into system standard outputs; "llama onError: "+JSON Stringify($2)))
		
		This.llama:=cs.llama.llama.new(This.port; Null; $home; $options; $event)
		This.startedHere:=True
		
		// wait for /health (up to 120 s)
		var $i : Integer
		For ($i; 1; 240)
			If (This.isReady())
				LOG EVENT(Into system standard outputs; "llama-server ready after "+String($i*500)+" ms")
				$i:=10000
			Else 
				DELAY PROCESS(Current process; 30)
			End if 
		End for 
		
		If (Not(This.isReady()))
			LOG EVENT(Into system standard outputs; "FATAL llama-server did not become ready")
		End if 
		
	End if 
	

// stop only a server this run started (see 4dcli, shared-desktop)
Function stop()
	
	If (This.startedHere)
		This.llama.terminate()
		This.startedHere:=False
	End if 
	

Function embedDocuments($texts : Collection)->$vectors : Collection
	
	var $out : Collection:=New collection()
	var $count : Integer:=$texts.length
	var $step : Integer:=This.batchSize
	var $start : Integer
	For ($start; 1; $count; $step)
		var $last : Integer:=$start+$step-1
		If ($last>$count)
			$last:=$count
		End if 
		var $batch : Collection:=New collection()
		var $t : Integer
		For ($t; $start; $last)
			$batch.push(This.documentPrefix+$texts[$t-1])
		End for 
		$out:=$out.concat(This.embedBatch($batch; $start; $count))
		var $batchIndex : Integer:=(($start-1)\$step)+1
		If ($batchIndex%20=0)
			LOG EVENT(Into system standard outputs; "embedded "+String($last)+"/"+String($count))
		End if 
	End for 
	
	return $out
	

Function embedQuery($text : Text)->$vector : 4D.Vector
	
	var $batch : Collection:=New collection(This.queryPrefix+$text)
	var $vectors : Collection:=This.embedBatch($batch; 1; 1)
	return $vectors[0]
	

// one HTTP call, with a single retry; returns a collection of 4D.Vector
Function embedBatch($texts : Collection; $start : Integer; $count : Integer)->$vectors : Collection
	
	var $attempt : Integer
	For ($attempt; 1; 2)
		Try 
			If ($client=Null)
				$client:=cs.AIKit.OpenAI.new({baseURL: "http://127.0.0.1:"+String(This.port)+"/v1"; apiKey: "local"})
			End if 
			var $result : Object:=$client.embeddings.create($texts; This.modelName)
			return $result.vectors
		Catch 
			LOG EVENT(Into system standard outputs; "embedBatch error at "+String($start)+"/"+String($count)+" attempt "+String($attempt))
			DELAY PROCESS(Current process; 60)
		End try 
	End for 
	
	LOG EVENT(Into system standard outputs; "FATAL embedBatch failed twice at "+String($start))
	File("/PACKAGE/build.FAILED").setText("embedBatch at "+String($start))
	QUIT 4D(1)
