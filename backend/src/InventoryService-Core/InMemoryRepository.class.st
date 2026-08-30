"
Port of the abstract InMemoryRepository<T> from the Spring version.

An OrderedDictionary preserves insertion order the way LinkedHashMap did, which
matters because several endpoints return items in file order and the tests
assert on it.

Why no database: the dataset is small and the exercise is about domain modelling,
not persistence. In production this would be PostgreSQL, or Voyage if the object
graph stayed the natural shape.
"
Class {
	#name : 'InMemoryRepository',
	#superclass : 'Object',
	#instVars : [ 'store' ],
	#category : 'InventoryService-Core',
	#package : 'InventoryService-Core'
}

{ #category : 'initialization' }
InMemoryRepository >> initialize [

	super initialize.
	store := OrderedDictionary new
]

{ #category : 'adding' }
InMemoryRepository >> save: anItem [
	"Answer false when the id is already taken. The loader turns that into a
	 'skipping duplicate' warning instead of overwriting — first entry wins."

	| key |
	key := anItem id.
	(store includesKey: key) ifTrue: [ ^ false ].
	store at: key put: anItem.
	^ true
]

{ #category : 'accessing' }
InMemoryRepository >> findById: anId [
	"Answer the item, or nil. Callers that need a hard failure use
	 findRequiredById: instead."

	^ store at: anId ifAbsent: [ nil ]
]

{ #category : 'accessing' }
InMemoryRepository >> findById: anId ifAbsent: aBlock [

	^ store at: anId ifAbsent: aBlock
]

{ #category : 'testing' }
InMemoryRepository >> includesId: anId [

	^ store includesKey: anId
]

{ #category : 'accessing' }
InMemoryRepository >> findAll [
	"A copy, so callers cannot mutate the store by accident."

	^ store values asArray
]

{ #category : 'accessing' }
InMemoryRepository >> count [

	^ store size
]

{ #category : 'removing' }
InMemoryRepository >> removeAll [
	"Used by tests to get a clean repository between cases."

	store removeAll
]
