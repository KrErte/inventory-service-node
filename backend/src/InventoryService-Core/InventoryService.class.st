"
Counts across the whole inventory. Port of the Java InventoryService.
"
Class {
	#name : 'InventoryService',
	#superclass : 'Object',
	#instVars : [ 'locationRepository', 'equipmentRepository', 'connectionRepository' ],
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'instance creation' }
InventoryService class >> locations: aLocationRepository equipment: anEquipmentRepository connections: aConnectionRepository [

	^ self new
		  setLocations: aLocationRepository
		  equipment: anEquipmentRepository
		  connections: aConnectionRepository
]

{ #category : 'private' }
InventoryService >> setLocations: aLocationRepository equipment: anEquipmentRepository connections: aConnectionRepository [

	locationRepository := aLocationRepository.
	equipmentRepository := anEquipmentRepository.
	connectionRepository := aConnectionRepository
]

{ #category : 'querying' }
InventoryService >> summary [

	| activeCount |
	activeCount := connectionRepository activeCount.
	^ InventorySummary
		  locations: locationRepository count
		  equipment: equipmentRepository count
		  active: activeCount
		  inactive: connectionRepository count - activeCount
]
