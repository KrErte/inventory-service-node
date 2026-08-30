"
This is the build file.

Metacello reads me to work out which packages the project has, what order they
load in, and which external projects to fetch first. Everything build.gradle
declared, declared as a class instead of a config file.

Load from a clean Pharo image with:

	Metacello new
		baseline: 'InventoryService';
		repository: 'github://KrErte/inventory-service-node:main/backend/src';
		load.
"
Class {
	#name : 'BaselineOfInventoryService',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfInventoryService',
	#package : 'BaselineOfInventoryService'
}

{ #category : 'baselines' }
BaselineOfInventoryService >> baseline: spec [

	<baseline>
	spec for: #common do: [

		"External dependencies. NeoJSON ships with Pharo, so only the web layer
		 has to be fetched."
		spec
			baseline: 'Teapot'
			with: [ spec repository: 'github://zeroflag/Teapot:master/source' ].

		"Our own packages, innermost first."
		spec
			package: 'InventoryService-Model';
			package: 'InventoryService-Core'
			with: [ spec requires: #( 'InventoryService-Model' 'Teapot' ) ];
			package: 'InventoryService-Tests'
			with: [ spec requires: #( 'InventoryService-Core' ) ];
			package: 'InventoryService-Tests-Integration'
			with: [ spec requires: #( 'InventoryService-Tests' ) ].

		"Groups. The integration tests start a real HTTP server, and a socket that
		 refuses to bind blocks the UI process — which in a development image means
		 a frozen IDE and, if you kill it, an unsaved session lost. So they are
		 deliberately NOT part of 'default': you get them by asking, and CI asks."
		spec
			group: 'core' with: #( 'InventoryService-Model' 'InventoryService-Core' );
			group: 'tests' with: #( 'InventoryService-Tests' );
			group: 'integration' with: #( 'InventoryService-Tests-Integration' );
			group: 'default' with: #( 'core' 'tests' );
			group: 'all' with: #( 'core' 'tests' 'integration' ) ]
]
