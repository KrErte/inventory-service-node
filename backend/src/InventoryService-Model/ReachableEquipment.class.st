"
One row of the BFS result: a piece of equipment and how many hops it took to
reach it. Mirrors `record ReachableEquipment(Equipment equipment, int depth)`.
"
Class {
	#name : 'ReachableEquipment',
	#superclass : 'Object',
	#instVars : [ 'equipment', 'depth' ],
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'instance creation' }
ReachableEquipment class >> equipment: anEquipment depth: aDepth [

	^ self new setEquipment: anEquipment depth: aDepth
]

{ #category : 'private' }
ReachableEquipment >> setEquipment: anEquipment depth: aDepth [

	equipment := anEquipment.
	depth := aDepth
]

{ #category : 'accessing' }
ReachableEquipment >> equipment [

	^ equipment
]

{ #category : 'accessing' }
ReachableEquipment >> depth [

	^ depth
]

{ #category : 'comparing' }
ReachableEquipment >> isSortedBefore: another [
	"Shallower first, then by equipment id — the exact ordering the Java
	 Comparator produced, kept explicit so the sort block stays readable."

	depth = another depth ifFalse: [ ^ depth < another depth ].
	^ equipment id <= another equipment id
]

{ #category : 'converting' }
ReachableEquipment >> asDictionary [

	^ Dictionary new
		  at: 'equipment' put: equipment asDictionary;
		  at: 'depth' put: depth;
		  yourself
]

{ #category : 'printing' }
ReachableEquipment >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: equipment id asString;
		nextPutAll: ' @ ';
		print: depth;
		nextPut: $)
]
