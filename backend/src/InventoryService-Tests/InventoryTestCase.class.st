"
Common fixture for the service tests: three fresh repositories and a loader,
rebuilt before every test method.

SUnit gives each test method a new instance of the TestCase, so there is no
state leaking between cases — the same guarantee JUnit gives, from the framework
JUnit was ported from.
"
Class {
	#name : 'InventoryTestCase',
	#superclass : 'TestCase',
	#instVars : [ 'locations', 'equipment', 'connections', 'loader' ],
	#category : 'InventoryService-Tests',
	#package : 'InventoryService-Tests'
}

{ #category : 'testing' }
InventoryTestCase class >> isAbstract [

	^ self = InventoryTestCase
]

{ #category : 'running' }
InventoryTestCase >> setUp [

	super setUp.
	locations := LocationRepository new.
	equipment := EquipmentRepository new.
	connections := ConnectionRepository new.
	loader := InventoryDataLoader
		          locations: locations
		          equipment: equipment
		          connections: connections
]

{ #category : 'running' }
InventoryTestCase >> loadSample [

	loader loadFromString: InventoryTestData sampleJson
]

{ #category : 'accessing' }
InventoryTestCase >> equipmentService [

	^ EquipmentService
		  locations: locations
		  equipment: equipment
		  connections: connections
]

{ #category : 'accessing' }
InventoryTestCase >> inventoryService [

	^ InventoryService
		  locations: locations
		  equipment: equipment
		  connections: connections
]

{ #category : 'accessing' }
InventoryTestCase >> idsOf: aCollection [
	"Reachable equipment reduced to ids, in result order — what most assertions
	 here actually care about."

	^ (aCollection asArray collect: [ :each | each equipment id ])
]
