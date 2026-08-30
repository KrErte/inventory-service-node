"
The HTTP layer and the composition root.

Teapot is a micro framework over Zinc: a route is a pattern mapped to a block.
That is all @RestController gave us, minus the annotation processing.

This class is also the whole dependency-injection story. Spring scanned the
classpath; here `buildGraph` wires six objects by hand in twelve lines. With a
graph this size that is not boilerplate — it is the one file that answers 'what
depends on what' without indirection.
"
Class {
	#name : 'InventoryServer',
	#superclass : 'Object',
	#instVars : [ 'teapot', 'port', 'equipmentService', 'inventoryService', 'loader', 'locationRepository', 'equipmentRepository', 'connectionRepository' ],
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'accessing' }
InventoryServer class >> defaultPort [

	^ 8080
]

{ #category : 'accessing' }
InventoryServer class >> defaultDataFile [
	"Packaged next to the source tree. The Docker image copies it alongside."

	^ (Smalltalk os environment
		   at: 'INVENTORY_DATA_PATH'
		   ifAbsent: [ 'data/inventory.json' ]) asFileReference
]

{ #category : 'initialization' }
InventoryServer >> initialize [

	super initialize.
	port := self class defaultPort
]

{ #category : 'accessing' }
InventoryServer >> port [

	^ port
]

{ #category : 'accessing' }
InventoryServer >> port: aPortNumber [

	port := aPortNumber
]

{ #category : 'accessing' }
InventoryServer >> equipmentService [

	^ equipmentService
]

{ #category : 'accessing' }
InventoryServer >> inventoryService [

	^ inventoryService
]

{ #category : 'accessing' }
InventoryServer >> loader [

	^ loader
]

{ #category : 'initialization' }
InventoryServer >> buildGraph [
	"The container, in full."

	locationRepository := LocationRepository new.
	equipmentRepository := EquipmentRepository new.
	connectionRepository := ConnectionRepository new.

	loader := InventoryDataLoader
		          locations: locationRepository
		          equipment: equipmentRepository
		          connections: connectionRepository.

	equipmentService := EquipmentService
		                    locations: locationRepository
		                    equipment: equipmentRepository
		                    connections: connectionRepository.

	inventoryService := InventoryService
		                    locations: locationRepository
		                    equipment: equipmentRepository
		                    connections: connectionRepository
]

{ #category : 'initialization' }
InventoryServer >> loadDataFrom: aFileReference [

	loader loadFromFile: aFileReference
]

{ #category : 'running' }
InventoryServer >> start [

	^ self startWithData: self class defaultDataFile
]

{ #category : 'running' }
InventoryServer >> startWithData: aFileReference [
	"Full startup: wire the graph, load the data, then open the port. Splitting
	 these three lets the integration tests reuse the wiring with fixture data
	 instead of the packaged file."

	self buildGraph.
	self loadDataFrom: aFileReference.
	^ self startServerOnly
]

{ #category : 'running' }
InventoryServer >> startServerOnly [
	"Routes only. Assumes buildGraph has already run."

	"#defaultOutput applies to every route. The per-route `output:` modifier does
	 not: it attaches to the most recently declared route, so writing it once at
	 the end of a cascade silently JSON-encodes only the last one and leaves the
	 rest answering printString."
	teapot := Teapot configure: {
			          #port -> port.
			          #defaultOutput -> #json.
			          #debugMode -> false }.

	teapot
		GET: '/api/v1/locations/<locationId>/equipment'
		-> [ :request |
			(equipmentService equipmentAtLocation: (request at: #locationId))
				collect: [ :each | each asDictionary ] ];

		GET: '/api/v1/equipment/<equipmentId>/connections'
		-> [ :request |
			(equipmentService connectionsFor: (request at: #equipmentId))
				collect: [ :each | each asDictionary ] ];

		GET: '/api/v1/equipment/<equipmentId>/connected'
		-> [ :request |
			(equipmentService
				 connectedFrom: (request at: #equipmentId)
				 depth: (self depthFrom: request)) asArray
				collect: [ :each | each asDictionary ] ];

		GET: '/api/v1/inventory/summary'
		-> [ :request | inventoryService summary asDictionary ];

		"One handler for the one error type — this is the whole
		 @RestControllerAdvice."
		exception: InventoryError -> [ :error :request | self responseFor: error ];

		start.

	Transcript
		show: 'Inventory service listening on port ' , port asString;
		cr;
		flush.
	^ self
]

{ #category : 'running' }
InventoryServer >> stop [

	teapot ifNotNil: [ teapot stop ]
]

{ #category : 'private' }
InventoryServer >> depthFrom: aRequest [
	"Replaces the Spring @RequestParam whose default value was 1. Query values
	 arrive as strings, and a non-numeric one is a client error, not a server
	 error."

	| raw |
	raw := aRequest at: #depth ifAbsent: [ '1' ].
	^ (raw allSatisfy: [ :char | char isDigit or: [ char = $- ] ])
		  ifTrue: [ raw asInteger ]
		  ifFalse: [ InventoryError badRequest: 'Depth must be an integer' ]
]

{ #category : 'private' }
InventoryServer >> responseFor: anError [
	"Build the error body by hand so every failure answers the same four keys.
	 Zinc's response object is used directly rather than a Teapot convenience, so
	 the status code is explicit."

	| response |
	response := ZnResponse new.
	response statusLine: (ZnStatusLine code: anError httpStatus).
	response entity: (ZnEntity
			 with: (NeoJSONWriter toString: anError asDictionary)
			 type: ZnMimeType applicationJson).
	^ response
]
