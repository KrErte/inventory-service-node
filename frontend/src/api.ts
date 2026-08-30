import type {
  Connection,
  Equipment,
  InventorySummary,
  ReachableEquipment,
} from './types';

const BASE = '/api/v1';

/**
 * Thrown for any non-2xx response, carrying the server's own message.
 *
 * The Pharo side answers a consistent four-key body on every failure, so there
 * is exactly one shape to parse and the UI can always show a real explanation
 * instead of "something went wrong".
 */
export class ApiRequestError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'ApiRequestError';
  }
}

async function get<T>(path: string): Promise<T> {
  const response = await fetch(`${BASE}${path}`, {
    headers: { Accept: 'application/json' },
  });

  if (!response.ok) {
    let message = `${response.status} ${response.statusText}`;
    try {
      const body = (await response.json()) as { message?: string };
      if (body.message) message = body.message;
    } catch {
      // Body was not the documented JSON shape; the status line has to do.
    }
    throw new ApiRequestError(response.status, message);
  }

  return (await response.json()) as T;
}

export const api = {
  summary: () => get<InventorySummary>('/inventory/summary'),

  equipmentAtLocation: (locationId: string) =>
    get<Equipment[]>(`/locations/${encodeURIComponent(locationId)}/equipment`),

  connectionsFor: (equipmentId: string) =>
    get<Connection[]>(`/equipment/${encodeURIComponent(equipmentId)}/connections`),

  connectedFrom: (equipmentId: string, depth: number) =>
    get<ReachableEquipment[]>(
      `/equipment/${encodeURIComponent(equipmentId)}/connected?depth=${depth}`,
    ),
};

/**
 * There is no endpoint that lists locations, so the ids are seeded here.
 *
 * That is a genuine gap in the original assignment's API — the Java service had
 * the same one. A production version would add GET /api/v1/locations; noted in
 * the README rather than papered over silently.
 */
export const KNOWN_LOCATION_IDS = ['LOC-1', 'LOC-2'];
