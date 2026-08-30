"
I am the abstract superclass of the four value objects in this service.

The Java version used records, which gave field access, equality and a
constructor for free. Smalltalk has no records, so I carry the two pieces of
that which are actually shared: reading a required field out of parsed JSON,
and failing loudly when it is missing.

Subclasses are immutable by convention — the setters are private and only the
class-side instance creation methods call them.
"
Class {
	#name : 'InventoryModel',
	#superclass : 'Object',
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'parsing' }
InventoryModel class >> from: aDictionary at: aKey [
	"Required field. Java records enforced this with Objects.requireNonNull in
	 the compact constructor; JSON gives us no such guarantee, so we check."

	| value |
	value := aDictionary at: aKey ifAbsent: [ nil ].
	(value isNil or: [ value = '' ]) ifTrue: [
		self error: self name , ' is missing required field ''' , aKey , '''' ].
	^ value
]

{ #category : 'parsing' }
InventoryModel class >> from: aDictionary optionalAt: aKey [
	"Optional field. A broken reference is still data worth keeping — the loader
	 warns about it rather than dropping the record."

	^ aDictionary at: aKey ifAbsent: [ nil ]
]

{ #category : 'parsing' }
InventoryModel class >> statusFrom: aDictionary [
	"Status is modelled as a Symbol. Symbols are unique and compare by identity,
	 which is as close as Smalltalk gets to a Java enum without a class per value."

	| raw |
	raw := self from: aDictionary at: 'status'.
	^ (#( 'ACTIVE' 'INACTIVE' ) includes: raw)
		  ifTrue: [ raw asSymbol ]
		  ifFalse: [ self error: self name , ' has unknown status ''' , raw asString , '''' ]
]

{ #category : 'accessing' }
InventoryModel >> id [

	^ self subclassResponsibility
]

{ #category : 'converting' }
InventoryModel >> asDictionary [
	"The JSON body for this object. Written by hand rather than through a NeoJSON
	 mapping: four small objects do not justify a mapping layer, and an explicit
	 dictionary makes the wire format greppable."

	^ self subclassResponsibility
]

{ #category : 'comparing' }
InventoryModel >> = anObject [
	"Value semantics on identity field only, matching how the repositories key
	 these objects."

	^ self class = anObject class and: [ self id = anObject id ]
]

{ #category : 'comparing' }
InventoryModel >> hash [

	^ self class hash bitXor: self id hash
]

{ #category : 'printing' }
InventoryModel >> printOn: aStream [

	super printOn: aStream.
	aStream nextPutAll: '('; nextPutAll: self id asString; nextPut: $)
]
