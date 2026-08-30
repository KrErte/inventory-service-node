"
A physical site. Mirrors `record Location(String id, String name, double latitude, double longitude)`.
"
Class {
	#name : 'Location',
	#superclass : 'InventoryModel',
	#instVars : [ 'id', 'name', 'latitude', 'longitude' ],
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'instance creation' }
Location class >> fromDictionary: aDictionary [

	^ self new
		  setId: (self from: aDictionary at: 'id')
		  name: (self from: aDictionary at: 'name')
		  latitude: (self from: aDictionary optionalAt: 'latitude')
		  longitude: (self from: aDictionary optionalAt: 'longitude')
]

{ #category : 'instance creation' }
Location class >> id: anId name: aName latitude: aLatitude longitude: aLongitude [

	^ self new setId: anId name: aName latitude: aLatitude longitude: aLongitude
]

{ #category : 'private' }
Location >> setId: anId name: aName latitude: aLatitude longitude: aLongitude [

	id := anId.
	name := aName.
	latitude := aLatitude.
	longitude := aLongitude
]

{ #category : 'accessing' }
Location >> id [

	^ id
]

{ #category : 'accessing' }
Location >> name [

	^ name
]

{ #category : 'accessing' }
Location >> latitude [

	^ latitude
]

{ #category : 'accessing' }
Location >> longitude [

	^ longitude
]

{ #category : 'converting' }
Location >> asDictionary [

	^ Dictionary new
		  at: 'id' put: id;
		  at: 'name' put: name;
		  at: 'latitude' put: latitude;
		  at: 'longitude' put: longitude;
		  yourself
]
