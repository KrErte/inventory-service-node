"
Tests for equipment queries and the BFS traversal.

Port of EquipmentServiceTest from the Java version, with the same cases plus two
the original left implicit: the cyclic graph and the negative depth.
"
Class {
	#name : 'EquipmentServiceTest',
	#superclass : 'InventoryTestCase',
	#category : 'InventoryService-Tests',
	#package : 'InventoryService-Tests'
}

{ #category : 'tests - equipment by location' }
EquipmentServiceTest >> testEquipmentAtLocationReturnsInstalledEquipment [

	self loadSample.
	self
		assert: ((self equipmentService equipmentAtLocation: 'LOC-1')
				 collect: [ :each | each id ])
		equals: #( 'A' 'B' 'E' )
]

{ #category : 'tests - equipment by location' }
EquipmentServiceTest >> testEquipmentAtLocationReturnsEmptyWhenNothingInstalled [

	self loadSample.
	locations save: (Location id: 'LOC-3' name: 'Tartu' latitude: 58.38 longitude: 26.72).
	self assert: (self equipmentService equipmentAtLocation: 'LOC-3') isEmpty
]

{ #category : 'tests - equipment by location' }
EquipmentServiceTest >> testEquipmentAtUnknownLocationIsNotFound [

	self loadSample.
	self
		should: [ self equipmentService equipmentAtLocation: 'LOC-404' ]
		raise: InventoryError
		withExceptionDo: [ :error |
			self assert: error httpStatus equals: 404.
			self assert: error messageText equals: 'Location not found: LOC-404' ]
]

{ #category : 'tests - connections' }
EquipmentServiceTest >> testConnectionsForEquipmentMatchesBothEnds [
	"B is the source of CON-BC and CON-BE, and the target of CON-AB. All three
	 count, because connections are undirected for query purposes."

	self loadSample.
	self
		assert: ((self equipmentService connectionsFor: 'B')
				 collect: [ :each | each id ]) asSortedCollection asArray
		equals: #( 'CON-AB' 'CON-BC' 'CON-BE' )
]

{ #category : 'tests - connections' }
EquipmentServiceTest >> testConnectionsForUnknownEquipmentIsNotFound [

	self loadSample.
	self
		should: [ self equipmentService connectionsFor: 'NOPE' ]
		raise: InventoryError
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedAtDepthOneSkipsInactiveConnections [
	"A is connected to B (active) and E (inactive). Only B is reachable, which is
	 the example the assignment spells out."

	self loadSample.
	self
		assert: (self idsOf: (self equipmentService connectedFrom: 'A' depth: 1))
		equals: #( 'B' )
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedAtDepthTwoReachesSecondLevel [
	"From A: B at depth 1, then C and E at depth 2. E is reachable here even
	 though A-E is inactive, because B-E is active — the equipment's own INACTIVE
	 status does not block traversal, only connection status does."

	self loadSample.
	self
		assert: (self idsOf: (self equipmentService connectedFrom: 'A' depth: 2))
		equals: #( 'B' 'C' 'E' )
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedAtDepthThreeReachesWholeComponent [

	self loadSample.
	self
		assert: (self idsOf: (self equipmentService connectedFrom: 'A' depth: 3))
		equals: #( 'B' 'C' 'E' 'D' )
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedResultIsOrderedByDepthThenId [

	| result |
	self loadSample.
	result := (self equipmentService connectedFrom: 'A' depth: 3) asArray.
	self assert: (result collect: [ :each | each depth ]) equals: #( 1 2 2 3 ).
	self assert: (result first equipment id) equals: 'B'.
	self assert: (result second equipment id) equals: 'C'.
	self assert: (result third equipment id) equals: 'E'
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedExcludesStartingEquipment [

	self loadSample.
	self deny: ((self idsOf: (self equipmentService connectedFrom: 'A' depth: 3))
			 includes: 'A')
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedAtDepthZeroIsEmpty [

	self loadSample.
	self assert: (self equipmentService connectedFrom: 'A' depth: 0) isEmpty
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedSkipsConnectionToUnknownEquipment [
	"CON-BROKEN links D to DOES-NOT-EXIST. Traversing from D must not produce a
	 phantom entry, and must not fail."

	self loadSample.
	self
		assert: (self idsOf: (self equipmentService connectedFrom: 'D' depth: 1))
		equals: #( 'C' )
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedTerminatesOnCyclicGraph [
	"X-Y-Z-X. The visited set is what stops this from looping forever."

	loader loadFromString: InventoryTestData cyclicJson.
	self
		assert: (self idsOf: (self equipmentService connectedFrom: 'X' depth: 10))
		equals: #( 'Y' 'Z' )
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testConnectedFromUnknownEquipmentIsNotFound [

	self loadSample.
	self
		should: [ self equipmentService connectedFrom: 'NOPE' depth: 1 ]
		raise: InventoryError
]

{ #category : 'tests - traversal' }
EquipmentServiceTest >> testNegativeDepthIsBadRequest [

	self loadSample.
	self
		should: [ self equipmentService connectedFrom: 'A' depth: -1 ]
		raise: InventoryError
		withExceptionDo: [ :error | self assert: error httpStatus equals: 400 ]
]
