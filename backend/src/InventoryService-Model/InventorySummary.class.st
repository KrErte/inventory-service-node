"
Counts across the whole inventory. Mirrors
`record InventorySummary(int locationCount, int equipmentCount, int activeConnectionCount, int inactiveConnectionCount)`.
"
Class {
	#name : 'InventorySummary',
	#superclass : 'Object',
	#instVars : [ 'locationCount', 'equipmentCount', 'activeConnectionCount', 'inactiveConnectionCount' ],
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'instance creation' }
InventorySummary class >> locations: aLocationCount equipment: anEquipmentCount active: anActiveCount inactive: anInactiveCount [

	^ self new
		  setLocations: aLocationCount
		  equipment: anEquipmentCount
		  active: anActiveCount
		  inactive: anInactiveCount
]

{ #category : 'private' }
InventorySummary >> setLocations: aLocationCount equipment: anEquipmentCount active: anActiveCount inactive: anInactiveCount [

	locationCount := aLocationCount.
	equipmentCount := anEquipmentCount.
	activeConnectionCount := anActiveCount.
	inactiveConnectionCount := anInactiveCount
]

{ #category : 'accessing' }
InventorySummary >> locationCount [

	^ locationCount
]

{ #category : 'accessing' }
InventorySummary >> equipmentCount [

	^ equipmentCount
]

{ #category : 'accessing' }
InventorySummary >> activeConnectionCount [

	^ activeConnectionCount
]

{ #category : 'accessing' }
InventorySummary >> inactiveConnectionCount [

	^ inactiveConnectionCount
]

{ #category : 'converting' }
InventorySummary >> asDictionary [

	^ Dictionary new
		  at: 'locationCount' put: locationCount;
		  at: 'equipmentCount' put: equipmentCount;
		  at: 'activeConnectionCount' put: activeConnectionCount;
		  at: 'inactiveConnectionCount' put: inactiveConnectionCount;
		  yourself
]
