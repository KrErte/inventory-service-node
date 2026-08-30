"
A link between two pieces of equipment. Mirrors
`record Connection(String id, String sourceEquipmentId, String targetEquipmentId, Status status)`.

Connections are treated as undirected for querying and traversal — the same
assumption the Java README documented.
"
Class {
	#name : 'Connection',
	#superclass : 'InventoryModel',
	#instVars : [ 'id', 'sourceEquipmentId', 'targetEquipmentId', 'status' ],
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'instance creation' }
Connection class >> fromDictionary: aDictionary [

	^ self new
		  setId: (self from: aDictionary at: 'id')
		  source: (self from: aDictionary at: 'sourceEquipmentId')
		  target: (self from: aDictionary at: 'targetEquipmentId')
		  status: (self statusFrom: aDictionary)
]

{ #category : 'instance creation' }
Connection class >> id: anId source: aSourceId target: aTargetId status: aStatus [

	^ self new setId: anId source: aSourceId target: aTargetId status: aStatus
]

{ #category : 'private' }
Connection >> setId: anId source: aSourceId target: aTargetId status: aStatus [

	id := anId.
	sourceEquipmentId := aSourceId.
	targetEquipmentId := aTargetId.
	status := aStatus
]

{ #category : 'accessing' }
Connection >> id [

	^ id
]

{ #category : 'accessing' }
Connection >> sourceEquipmentId [

	^ sourceEquipmentId
]

{ #category : 'accessing' }
Connection >> targetEquipmentId [

	^ targetEquipmentId
]

{ #category : 'accessing' }
Connection >> status [

	^ status
]

{ #category : 'testing' }
Connection >> isActive [

	^ status = #ACTIVE
]

{ #category : 'testing' }
Connection >> touches: anEquipmentId [

	^ sourceEquipmentId = anEquipmentId or: [ targetEquipmentId = anEquipmentId ]
]

{ #category : 'accessing' }
Connection >> otherEndFrom: anEquipmentId [
	"The equipment at the far end of this connection, seen from anEquipmentId."

	^ sourceEquipmentId = anEquipmentId
		  ifTrue: [ targetEquipmentId ]
		  ifFalse: [ sourceEquipmentId ]
]

{ #category : 'converting' }
Connection >> asDictionary [

	^ Dictionary new
		  at: 'id' put: id;
		  at: 'sourceEquipmentId' put: sourceEquipmentId;
		  at: 'targetEquipmentId' put: targetEquipmentId;
		  at: 'status' put: status asString;
		  yourself
]
