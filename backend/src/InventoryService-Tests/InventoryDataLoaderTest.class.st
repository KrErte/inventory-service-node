"
Tests for the loader's data-quality policy. Port of InventoryDataLoaderTest.

Where the Java test had to install a log appender to observe warnings, here the
loader collects them, so the policy is asserted directly.
"
Class {
	#name : 'InventoryDataLoaderTest',
	#superclass : 'InventoryTestCase',
	#category : 'InventoryService-Tests',
	#package : 'InventoryService-Tests'
}

{ #category : 'tests - happy path' }
InventoryDataLoaderTest >> testLoadsEverythingFromSample [

	self loadSample.
	self assert: locations count equals: 2.
	self assert: equipment count equals: 6.
	self assert: connections count equals: 7
]

{ #category : 'tests - happy path' }
InventoryDataLoaderTest >> testPreservesFileOrder [
	"Insertion order is part of the contract: list endpoints return items in the
	 order the file declared them."

	self loadSample.
	self
		assert: (equipment findAll collect: [ :each | each id ])
		equals: #( 'A' 'B' 'C' 'D' 'E' 'F' )
]

{ #category : 'tests - happy path' }
InventoryDataLoaderTest >> testParsesStatusAsSymbol [

	self loadSample.
	self assert: (equipment findById: 'A') status equals: #ACTIVE.
	self assert: (equipment findById: 'E') status equals: #INACTIVE.
	self deny: (equipment findById: 'E') isActive
]

{ #category : 'tests - broken references' }
InventoryDataLoaderTest >> testKeepsEquipmentWithUnknownLocation [
	"Equipment F points at LOC-999. The equipment is real, only the reference is
	 broken, so it is loaded and warned about."

	self loadSample.
	self assert: (equipment includesId: 'F').
	self assert: (loader warnings anySatisfy: [ :each |
			 each includesSubstring: 'Equipment F references unknown location LOC-999' ])
]

{ #category : 'tests - broken references' }
InventoryDataLoaderTest >> testKeepsConnectionWithUnknownTarget [

	self loadSample.
	self assert: (connections includesId: 'CON-BROKEN').
	self assert: (loader warnings anySatisfy: [ :each |
			 each includesSubstring: 'CON-BROKEN references unknown target equipment' ])
]

{ #category : 'tests - broken references' }
InventoryDataLoaderTest >> testSampleProducesExactlyTwoWarnings [
	"The dataset has two documented inconsistencies and no more. If this number
	 changes, either the data or the policy changed and someone should know."

	self loadSample.
	self assert: loader warnings size equals: 2
]

{ #category : 'tests - duplicates' }
InventoryDataLoaderTest >> testFirstDuplicateWins [

	loader loadFromString: InventoryTestData duplicateIdJson.
	self assert: equipment count equals: 1.
	self assert: (equipment findById: 'A') name equals: 'First A'.
	self assert: (loader warnings anySatisfy: [ :each |
			 each includesSubstring: 'Skipping duplicate equipment id: A' ])
]

{ #category : 'tests - fail fast' }
InventoryDataLoaderTest >> testMissingIdFailsFast [
	"A structurally broken record has nothing worth keeping, so unlike a broken
	 reference it stops the load."

	self should: [ loader loadFromString: InventoryTestData missingIdJson ] raise: Error
]

{ #category : 'tests - fail fast' }
InventoryDataLoaderTest >> testUnknownStatusFailsFast [

	self
		should: [
			Equipment fromDictionary: (Dictionary new
					 at: 'id' put: 'Q';
					 at: 'name' put: 'Q';
					 at: 'status' put: 'MAYBE';
					 yourself) ]
		raise: Error
]
