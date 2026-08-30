"
Fixture data for the test suite.

The sample set is held here as a string rather than read from data/inventory.json
so the tests do not depend on the working directory, and so the deliberately
broken variants sit next to the good one.

Note on quoting: inside a Smalltalk string literal a double quote is an ordinary
character — only single quotes need doubling. So the JSON below is written
exactly as JSON, with no escaping at all.
"
Class {
	#name : 'InventoryTestData',
	#superclass : 'Object',
	#category : 'InventoryService-Tests',
	#package : 'InventoryService-Tests'
}

{ #category : 'fixtures' }
InventoryTestData class >> sampleJson [
	"The assignment dataset, including its two intentional inconsistencies:
	 equipment F points at a location that does not exist, and CON-BROKEN points
	 at equipment that does not exist."

	^ '{
  "locations": [
    { "id": "LOC-1", "name": "Tallinn", "latitude": 59.4370, "longitude": 24.7536 },
    { "id": "LOC-2", "name": "Parnu", "latitude": 58.3859, "longitude": 24.4971 }
  ],
  "equipment": [
    { "id": "A", "name": "Equipment A", "type": "ROUTER", "locationId": "LOC-1", "status": "ACTIVE" },
    { "id": "B", "name": "Equipment B", "type": "SWITCH", "locationId": "LOC-1", "status": "ACTIVE" },
    { "id": "C", "name": "Equipment C", "type": "SWITCH", "locationId": "LOC-2", "status": "ACTIVE" },
    { "id": "D", "name": "Equipment D", "type": "ROUTER", "locationId": "LOC-2", "status": "ACTIVE" },
    { "id": "E", "name": "Equipment E", "type": "ACCESS_DEVICE", "locationId": "LOC-1", "status": "INACTIVE" },
    { "id": "F", "name": "Equipment F", "type": "UNKNOWN", "locationId": "LOC-999", "status": "ACTIVE" }
  ],
  "connections": [
    { "id": "CON-AB", "sourceEquipmentId": "A", "targetEquipmentId": "B", "status": "ACTIVE" },
    { "id": "CON-BC", "sourceEquipmentId": "B", "targetEquipmentId": "C", "status": "ACTIVE" },
    { "id": "CON-CD", "sourceEquipmentId": "C", "targetEquipmentId": "D", "status": "ACTIVE" },
    { "id": "CON-BE", "sourceEquipmentId": "B", "targetEquipmentId": "E", "status": "ACTIVE" },
    { "id": "CON-CE", "sourceEquipmentId": "C", "targetEquipmentId": "E", "status": "ACTIVE" },
    { "id": "CON-AE", "sourceEquipmentId": "A", "targetEquipmentId": "E", "status": "INACTIVE" },
    { "id": "CON-BROKEN", "sourceEquipmentId": "D", "targetEquipmentId": "DOES-NOT-EXIST", "status": "ACTIVE" }
  ]
}'
]

{ #category : 'fixtures' }
InventoryTestData class >> duplicateIdJson [
	"Two equipment records share id A. First entry wins, second is warned about."

	^ '{
  "locations": [ { "id": "LOC-1", "name": "Tallinn", "latitude": 1, "longitude": 1 } ],
  "equipment": [
    { "id": "A", "name": "First A", "type": "ROUTER", "locationId": "LOC-1", "status": "ACTIVE" },
    { "id": "A", "name": "Second A", "type": "SWITCH", "locationId": "LOC-1", "status": "ACTIVE" }
  ],
  "connections": []
}'
]

{ #category : 'fixtures' }
InventoryTestData class >> cyclicJson [
	"A triangle. Without a visited set the traversal would never terminate."

	^ '{
  "locations": [ { "id": "LOC-1", "name": "Tallinn", "latitude": 1, "longitude": 1 } ],
  "equipment": [
    { "id": "X", "name": "X", "type": "ROUTER", "locationId": "LOC-1", "status": "ACTIVE" },
    { "id": "Y", "name": "Y", "type": "ROUTER", "locationId": "LOC-1", "status": "ACTIVE" },
    { "id": "Z", "name": "Z", "type": "ROUTER", "locationId": "LOC-1", "status": "ACTIVE" }
  ],
  "connections": [
    { "id": "C1", "sourceEquipmentId": "X", "targetEquipmentId": "Y", "status": "ACTIVE" },
    { "id": "C2", "sourceEquipmentId": "Y", "targetEquipmentId": "Z", "status": "ACTIVE" },
    { "id": "C3", "sourceEquipmentId": "Z", "targetEquipmentId": "X", "status": "ACTIVE" }
  ]
}'
]

{ #category : 'fixtures' }
InventoryTestData class >> missingIdJson [
	"Structurally broken: no id. This must fail fast, not load with a warning."

	^ '{
  "locations": [ { "name": "Nameless", "latitude": 1, "longitude": 1 } ],
  "equipment": [],
  "connections": []
}'
]
