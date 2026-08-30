"
Equipment, keyed by id, plus the one derived query the API needs.
"
Class {
	#name : 'EquipmentRepository',
	#superclass : 'InMemoryRepository',
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'accessing' }
EquipmentRepository >> findByLocationId: aLocationId [

	^ self findAll select: [ :each | each locationId = aLocationId ]
]
