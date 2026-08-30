"
Connections, keyed by id.

findByEquipmentId: matches on either end, because connections are undirected for
query purposes — same assumption the Java version documented.
"
Class {
	#name : 'ConnectionRepository',
	#superclass : 'InMemoryRepository',
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'accessing' }
ConnectionRepository >> findByEquipmentId: anEquipmentId [

	^ self findAll select: [ :each | each touches: anEquipmentId ]
]

{ #category : 'accessing' }
ConnectionRepository >> activeCount [

	^ (self findAll select: [ :each | each isActive ]) size
]
