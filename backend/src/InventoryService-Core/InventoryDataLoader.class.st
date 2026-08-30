"
Port of InventoryDataLoader (ApplicationRunner) from the Spring version.

Data-quality policy is unchanged: warn and load. A broken *reference* keeps its
record, because the record itself is real and only the pointer is wrong. A
structurally broken record — missing id, unknown status — fails fast, because
there is nothing sensible to keep.

Warnings are collected into an instance variable as well as written to the
Transcript, so tests can assert on them instead of scraping log output. That is
one thing this port does better than the Java original, where the equivalent
test had to install a log appender.
"
Class {
	#name : 'InventoryDataLoader',
	#superclass : 'Object',
	#instVars : [ 'locationRepository', 'equipmentRepository', 'connectionRepository', 'warnings' ],
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'instance creation' }
InventoryDataLoader class >> locations: aLocationRepository equipment: anEquipmentRepository connections: aConnectionRepository [

	^ self new
		  setLocations: aLocationRepository
		  equipment: anEquipmentRepository
		  connections: aConnectionRepository
]

{ #category : 'initialization' }
InventoryDataLoader >> initialize [

	super initialize.
	warnings := OrderedCollection new
]

{ #category : 'private' }
InventoryDataLoader >> setLocations: aLocationRepository equipment: anEquipmentRepository connections: aConnectionRepository [

	locationRepository := aLocationRepository.
	equipmentRepository := anEquipmentRepository.
	connectionRepository := aConnectionRepository
]

{ #category : 'accessing' }
InventoryDataLoader >> warnings [

	^ warnings
]

{ #category : 'loading' }
InventoryDataLoader >> loadFromFile: aFileReference [

	^ self loadFromString: aFileReference contents
]

{ #category : 'loading' }
InventoryDataLoader >> loadFromString: aJsonString [

	| data |
	data := NeoJSONReader fromString: aJsonString.

	self loadLocations: (data at: 'locations' ifAbsent: [ #(  ) ]).
	self loadEquipment: (data at: 'equipment' ifAbsent: [ #(  ) ]).
	self loadConnections: (data at: 'connections' ifAbsent: [ #(  ) ]).

	Transcript showln: 'Inventory loaded: '
		, locationRepository count asString , ' locations, '
		, equipmentRepository count asString , ' equipment, '
		, connectionRepository count asString , ' connections'.
	^ self
]

{ #category : 'private' }
InventoryDataLoader >> loadLocations: aCollection [

	aCollection do: [ :each |
		| location |
		location := Location fromDictionary: each.
		(locationRepository save: location) ifFalse: [
			self warn: 'Skipping duplicate location id: ' , location id ] ]
]

{ #category : 'private' }
InventoryDataLoader >> loadEquipment: aCollection [

	aCollection do: [ :each |
		| equipment |
		equipment := Equipment fromDictionary: each.
		(equipmentRepository save: equipment)
			ifFalse: [ self warn: 'Skipping duplicate equipment id: ' , equipment id ]
			ifTrue: [
				(locationRepository includesId: equipment locationId) ifFalse: [
					self warn: 'Equipment ' , equipment id
						, ' references unknown location ' , equipment locationId asString ] ] ]
]

{ #category : 'private' }
InventoryDataLoader >> loadConnections: aCollection [

	aCollection do: [ :each |
		| connection |
		connection := Connection fromDictionary: each.
		(connectionRepository save: connection)
			ifFalse: [ self warn: 'Skipping duplicate connection id: ' , connection id ]
			ifTrue: [
				(equipmentRepository includesId: connection sourceEquipmentId) ifFalse: [
					self warn: 'Connection ' , connection id
						, ' references unknown source equipment ' , connection sourceEquipmentId ].
				(equipmentRepository includesId: connection targetEquipmentId) ifFalse: [
					self warn: 'Connection ' , connection id
						, ' references unknown target equipment ' , connection targetEquipmentId ] ] ]
]

{ #category : 'private' }
InventoryDataLoader >> warn: aMessage [

	warnings add: aMessage.
	Transcript showln: '[WARN] ' , aMessage
]
