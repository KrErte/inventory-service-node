"
Tests for the inventory summary. Port of InventoryServiceTest.
"
Class {
	#name : 'InventoryServiceTest',
	#superclass : 'InventoryTestCase',
	#category : 'InventoryService-Tests',
	#package : 'InventoryService-Tests'
}

{ #category : 'tests' }
InventoryServiceTest >> testSummaryCountsEverything [

	| summary |
	self loadSample.
	summary := self inventoryService summary.
	self assert: summary locationCount equals: 2.
	self assert: summary equipmentCount equals: 6.
	self assert: summary activeConnectionCount equals: 6.
	self assert: summary inactiveConnectionCount equals: 1
]

{ #category : 'tests' }
InventoryServiceTest >> testActiveAndInactiveSumToTotal [

	self loadSample.
	self
		assert: self inventoryService summary activeConnectionCount
			+ self inventoryService summary inactiveConnectionCount
		equals: connections count
]

{ #category : 'tests' }
InventoryServiceTest >> testSummaryOfEmptyInventoryIsAllZero [

	| summary |
	summary := self inventoryService summary.
	self assert: summary locationCount equals: 0.
	self assert: summary equipmentCount equals: 0.
	self assert: summary activeConnectionCount equals: 0.
	self assert: summary inactiveConnectionCount equals: 0
]

{ #category : 'tests' }
InventoryServiceTest >> testSummarySerialisesToTheDocumentedKeys [

	| dictionary |
	self loadSample.
	dictionary := self inventoryService summary asDictionary.
	self
		assert: dictionary keys asSortedCollection asArray
		equals: #( 'activeConnectionCount' 'equipmentCount' 'inactiveConnectionCount' 'locationCount' )
]
