/**
 * The API contract, mirrored from the Pharo model classes.
 *
 * Hand-maintained: unlike the Node/Nest plan, where a shared package could be
 * imported by both sides, a Smalltalk backend and a TypeScript frontend have no
 * common type system. The integration tests in InventoryService-Tests-Integration
 * assert on exactly these key names, so a rename on either side fails there.
 */

export type Status = 'ACTIVE' | 'INACTIVE';

export interface Location {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
}

export interface Equipment {
  id: string;
  name: string;
  type: string;
  locationId: string;
  status: Status;
}

export interface Connection {
  id: string;
  sourceEquipmentId: string;
  targetEquipmentId: string;
  status: Status;
}

export interface InventorySummary {
  locationCount: number;
  equipmentCount: number;
  activeConnectionCount: number;
  inactiveConnectionCount: number;
}

export interface ReachableEquipment {
  equipment: Equipment;
  depth: number;
}

/** Body produced by the Pharo error handler for every failure. */
export interface ApiError {
  status: number;
  error: string;
  message: string;
  timestamp: string;
}
