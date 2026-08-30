"
I am the single error type this service raises, ported from GlobalException.

Like there, I carry an HTTP status instead of the codebase growing one exception
class per failure mode. Teapot has exactly one handler for me, so every error
response has the same four-key shape no matter where it came from.
"
Class {
	#name : 'InventoryError',
	#superclass : 'Error',
	#instVars : [ 'httpStatus' ],
	#category : 'InventoryService-Model',
	#package : 'InventoryService-Model'
}

{ #category : 'signalling' }
InventoryError class >> notFound: aResourceType id: anId [
	"Mirrors the (resourceType, id, status) constructor of GlobalException."

	^ self new
		  httpStatus: 404;
		  signal: aResourceType , ' not found: ' , anId asString
]

{ #category : 'signalling' }
InventoryError class >> badRequest: aMessage [

	^ self new
		  httpStatus: 400;
		  signal: aMessage
]

{ #category : 'signalling' }
InventoryError class >> signal: aMessage status: aStatusCode [

	^ self new
		  httpStatus: aStatusCode;
		  signal: aMessage
]

{ #category : 'accessing' }
InventoryError >> httpStatus [

	^ httpStatus ifNil: [ 500 ]
]

{ #category : 'accessing' }
InventoryError >> httpStatus: aStatusCode [

	httpStatus := aStatusCode
]

{ #category : 'accessing' }
InventoryError >> reasonPhrase [
	"Equivalent of HttpStatus>>getReasonPhrase, which Pharo has no built-in for."

	^ #( #( 400 'Bad Request' ) #( 401 'Unauthorized' ) #( 403 'Forbidden' )
	     #( 404 'Not Found' ) #( 409 'Conflict' ) #( 422 'Unprocessable Entity' )
	     #( 500 'Internal Server Error' ) )
		  detect: [ :each | each first = self httpStatus ]
		  ifFound: [ :each | each second ]
		  ifNone: [ 'Error' ]
]

{ #category : 'converting' }
InventoryError >> asDictionary [
	"The response body. Same four keys the Java GlobalExceptionHandler built."

	^ Dictionary new
		  at: 'status' put: self httpStatus;
		  at: 'error' put: self reasonPhrase;
		  at: 'message' put: self messageText;
		  at: 'timestamp' put: DateAndTime now asUTC printString;
		  yourself
]
