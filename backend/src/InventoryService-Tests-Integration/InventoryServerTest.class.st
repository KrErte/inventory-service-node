"
End-to-end tests over real HTTP. Port of EquipmentControllerTest, which used
MockMvc; here we start the actual server on a spare port and call it with Zinc's
HTTP client, so routing, JSON serialisation and the error handler are all
exercised for real.

Kept in its own package so a hanging socket can never take the IDE with it:
the default load does not include it, and CI runs it headless.

This is the layer that most needs the coverage: everything below it is plain
Smalltalk, but the Teapot wiring is where a version mismatch would show up.
"
Class {
	#name : 'InventoryServerTest',
	#superclass : 'TestCase',
	#classInstVars : [ 'sharedServer' ],
	#category : 'InventoryService-Tests-Integration',
	#package : 'InventoryService-Tests-Integration'
}

{ #category : 'accessing' }
InventoryServerTest class >> httpPort [
	"A port unlikely to collide with a developer's running service.

	 Not named testPort: SUnit collects every method whose selector starts with
	 'test' as a test case, so an accessor with that prefix would be run as one."

	^ 18080
]

{ #category : 'accessing' }
InventoryServerTest class >> sharedServer [
	"One server for the whole test class, started on first use.

	 The obvious implementation — start in setUp, stop in tearDown — starts and
	 stops nine servers on the same port in quick succession, and the operating
	 system does not release the socket fast enough: from the sixth test onward
	 the bind fails and every remaining test errors. Since all of these tests are
	 read-only queries against fixture data, one shared instance is both correct
	 and an order of magnitude faster."

	^ sharedServer ifNil: [ sharedServer := self startServer ]
]

{ #category : 'accessing' }
InventoryServerTest class >> startServer [

	| server |
	server := InventoryServer new
		          port: self httpPort;
		          yourself.
	server buildGraph.
	server loader loadFromString: InventoryTestData sampleJson.
	server startServerOnly.
	^ server
]

{ #category : 'running' }
InventoryServerTest class >> tearDownClass [
	"Called once after the last test in this class."

	sharedServer ifNotNil: [
		sharedServer stop.
		sharedServer := nil ]
]

{ #category : 'accessing' }
InventoryServerTest >> baseUrl [

	^ 'http://localhost:' , self class httpPort asString
]

{ #category : 'running' }
InventoryServerTest >> setUp [

	super setUp.
	"Touch the accessor so the first test starts the server; later tests reuse it."
	self class sharedServer
]

{ #category : 'private' }
InventoryServerTest >> get: aPath [
	"Answer the parsed JSON body of a successful GET."

	^ NeoJSONReader fromString: (ZnClient new
			   url: self baseUrl , aPath;
			   timeout: 5;
			   get)
]

{ #category : 'private' }
InventoryServerTest >> statusOf: aPath [

	^ (ZnClient new
		   url: self baseUrl , aPath;
		   enforceHttpSuccess: false;
		   timeout: 5;
		   get;
		   response) code
]

{ #category : 'tests' }
InventoryServerTest >> testSummaryEndpoint [

	| body |
	body := self get: '/api/v1/inventory/summary'.
	self assert: (body at: 'locationCount') equals: 2.
	self assert: (body at: 'equipmentCount') equals: 6.
	self assert: (body at: 'activeConnectionCount') equals: 6.
	self assert: (body at: 'inactiveConnectionCount') equals: 1
]

{ #category : 'tests' }
InventoryServerTest >> testEquipmentByLocationEndpoint [

	| body |
	body := self get: '/api/v1/locations/LOC-1/equipment'.
	self assert: (body collect: [ :each | each at: 'id' ]) asArray equals: #( 'A' 'B' 'E' )
]

{ #category : 'tests' }
InventoryServerTest >> testConnectionsEndpoint [

	| body |
	body := self get: '/api/v1/equipment/B/connections'.
	self assert: body size equals: 3
]

{ #category : 'tests' }
InventoryServerTest >> testConnectedEndpointDefaultsToDepthOne [

	| body |
	body := self get: '/api/v1/equipment/A/connected'.
	self assert: body size equals: 1.
	self assert: ((body first at: 'equipment') at: 'id') equals: 'B'.
	self assert: (body first at: 'depth') equals: 1
]

{ #category : 'tests' }
InventoryServerTest >> testConnectedEndpointHonoursDepthParameter [

	| body |
	body := self get: '/api/v1/equipment/A/connected?depth=2'.
	self
		assert: (body collect: [ :each | (each at: 'equipment') at: 'id' ]) asArray
		equals: #( 'B' 'C' 'E' )
]

{ #category : 'tests - errors' }
InventoryServerTest >> testUnknownLocationAnswers404 [

	self assert: (self statusOf: '/api/v1/locations/LOC-404/equipment') equals: 404
]

{ #category : 'tests - errors' }
InventoryServerTest >> testUnknownEquipmentAnswers404 [

	self assert: (self statusOf: '/api/v1/equipment/NOPE/connections') equals: 404
]

{ #category : 'tests - errors' }
InventoryServerTest >> testNegativeDepthAnswers400 [

	self assert: (self statusOf: '/api/v1/equipment/A/connected?depth=-1') equals: 400
]

{ #category : 'tests - errors' }
InventoryServerTest >> testErrorBodyHasTheDocumentedShape [

	| body |
	body := NeoJSONReader fromString: (ZnClient new
			         url: self baseUrl , '/api/v1/equipment/NOPE/connections';
			         enforceHttpSuccess: false;
			         timeout: 5;
			         get).
	self assert: (body at: 'status') equals: 404.
	self assert: (body at: 'error') equals: 'Not Found'.
	self assert: (body at: 'message') equals: 'Equipment not found: NOPE'.
	self assert: (body includesKey: 'timestamp')
]
