//%attributes = {}
// Button: search with the vector index (IndexedVector) and time the query.
// Threshold 0.85 was calibrated on the built corpus: below it the ruri-v3
// cosine noise floor (unrelated texts ≈ 0.80) floods the result, and the
// vector index itself degrades toward full-scan times.

Form.indexedResult:=[]
Form.indexedTimer:=0

var $param : Object
$param:={vector: Form.currentVector; metric: "cosine"; threshold: 0.85}

var $t0 : Real:=Milliseconds
Form.indexedResult:=ds.Data.query("IndexedVector>=:1 order by IndexedVector desc"; $param)
Form.indexedTimer:=Round(Milliseconds-$t0; 0)
