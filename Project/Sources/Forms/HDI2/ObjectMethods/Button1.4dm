//%attributes = {}
// Button1: search without the vector index (NonIndexedVector) and time the
// query. Same data, same query shape - only the indexed attribute differs.

Form.nonIndexedResult:=[]
Form.nonIndexedTimer:=0

var $param : Object
$param:={vector: Form.currentVector; metric: "cosine"; threshold: 0.85}

var $t0 : Real:=Milliseconds
Form.nonIndexedResult:=ds.Data.query("NonIndexedVector>=:1 order by NonIndexedVector desc"; $param)
Form.nonIndexedTimer:=Round(Milliseconds-$t0; 0)
