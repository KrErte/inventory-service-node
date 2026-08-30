"
A piece of installed hardware. Mirrors
`record Equipment(String id, String name, String type, String locationId, Status status)`.

locationId is deliberately optional at parse time: the sample data contains
equipment F pointing at LOC-999, which does not exist. The record is real, only
the reference is broken, so it is loaded with a warning rather than rejected.
"
Class {
	#name : 'Equipment',
	#superclass : 'InventoryModel',
	#instVars : [ 'id', 'name', 'type', 'locationId', 'status' ],
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'instance creation' }
Equipment class >> fromDictionary: aDictionary [

	^ self new
		  setId: (self from: aDictionary at: 'id')
		  name: (self from: aDictionary at: 'name')
		  type: (self from: aDictionary optionalAt: 'type')
		  locationId: (self from: aDictionary optionalAt: 'locationId')
		  status: (self statusFrom: aDictionary)
]

{ #category : 'instance creation' }
Equipment class >> id: anId name: aName type: aType locationId: aLocationId status: aStatus [

	^ self new setId: anId name: aName type: aType locationId: aLocationId status: aStatus
]

{ #category : 'private' }
Equipment >> setId: anId name: aName type: aType locationId: aLocationId status: aStatus [

	id := anId.
	name := aName.
	type := aType.
	locationId := aLocationId.
	status := aStatus
]

{ #category : 'accessing' }
Equipment >> id [

	^ id
]

{ #category : 'accessing' }
Equipment >> name [

	^ name
]

{ #category : 'accessing' }
Equipment >> type [

	^ type
]

{ #category : 'accessing' }
Equipment >> locationId [

	^ locationId
]

{ #category : 'accessing' }
Equipment >> status [

	^ status
]

{ #category : 'testing' }
Equipment >> isActive [

	^ status = #ACTIVE
]

{ #category : 'converting' }
Equipment >> asDictionary [

	^ Dictionary new
		  at: 'id' put: id;
		  at: 'name' put: name;
		  at: 'type' put: type;
		  at: 'locationId' put: locationId;
		  at: 'status' put: status asString;
		  yourself
]
