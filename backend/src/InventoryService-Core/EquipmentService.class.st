"
Business logic for equipment queries, including the graph traversal.

Dependencies arrive through a class-side instance creation method rather than a
DI container. With three collaborators that is honest wiring, not boilerplate —
the whole 'container' is one method in InventoryServer.
"
Class {
	#name : 'EquipmentService',
	#superclass : 'Object',
	#instVars : [ 'locationRepository', 'equipmentRepository', 'connectionRepository' ],
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'instance creation' }
EquipmentService class >> locations: aLocationRepository equipment: anEquipmentRepository connections: aConnectionRepository [

	^ self new
		  setLocations: aLocationRepository
		  equipment: anEquipmentRepository
		  connections: aConnectionRepository
]

{ #category : 'private' }
EquipmentService >> setLocations: aLocationRepository equipment: anEquipmentRepository connections: aConnectionRepository [

	locationRepository := aLocationRepository.
	equipmentRepository := anEquipmentRepository.
	connectionRepository := aConnectionRepository
]

{ #category : 'querying' }
EquipmentService >> equipmentAtLocation: aLocationId [

	(locationRepository includesId: aLocationId) ifFalse: [
		InventoryError notFound: 'Location' id: aLocationId ].
	^ equipmentRepository findByLocationId: aLocationId
]

{ #category : 'querying' }
EquipmentService >> connectionsFor: anEquipmentId [

	(equipmentRepository includesId: anEquipmentId) ifFalse: [
		InventoryError notFound: 'Equipment' id: anEquipmentId ].
	^ connectionRepository findByEquipmentId: anEquipmentId
]

{ #category : 'querying' }
EquipmentService >> connectedFrom: anEquipmentId depth: maxDepth [
	"Breadth-first traversal over ACTIVE connections, answering every reachable
	 equipment together with the number of hops it took.

	 Line for line the Java algorithm. The depths dictionary doubles as the
	 visited set, which is what makes cyclic data terminate; the queue drives
	 level order; a node at maxDepth is not expanded further.

	 Pharo's OrderedCollection removeFirst is O(1), so unlike JavaScript there is
	 no need to fake a queue with a moving head index."

	| depths queue |
	(equipmentRepository includesId: anEquipmentId) ifFalse: [
		InventoryError notFound: 'Equipment' id: anEquipmentId ].
	maxDepth < 0 ifTrue: [
		InventoryError badRequest: 'Depth must not be negative' ].

	depths := OrderedDictionary new.
	depths at: anEquipmentId put: 0.
	queue := OrderedCollection with: anEquipmentId.

	[ queue isEmpty ] whileFalse: [
		| currentId currentDepth |
		currentId := queue removeFirst.
		currentDepth := depths at: currentId.
		currentDepth = maxDepth ifFalse: [
			(self activeNeighboursOf: currentId) do: [ :neighbourId |
				(depths includesKey: neighbourId) ifFalse: [
					depths at: neighbourId put: currentDepth + 1.
					queue addLast: neighbourId ] ] ] ].

	"The starting node is not part of its own result set."
	depths removeKey: anEquipmentId.

	^ (depths associations collect: [ :each |
		   ReachableEquipment
			   equipment: (equipmentRepository findById: each key)
			   depth: each value ])
		  asSortedCollection: [ :a :b | a isSortedBefore: b ]
]

{ #category : 'private' }
EquipmentService >> activeNeighboursOf: anEquipmentId [
	"Neighbours across ACTIVE connections only, in either direction.

	 The trailing includesId: filter is what makes CON-BROKEN harmless: it points
	 at DOES-NOT-EXIST, so the traversal simply never reaches it."

	^ ((connectionRepository findByEquipmentId: anEquipmentId)
		   select: [ :each | each isActive ])
		  inject: OrderedCollection new
		  into: [ :acc :connection |
			  | otherEnd |
			  otherEnd := connection otherEndFrom: anEquipmentId.
			  (equipmentRepository includesId: otherEnd) ifTrue: [ acc add: otherEnd ].
			  acc ]
]
