import { useQueries } from '@tanstack/react-query';
import { api, KNOWN_LOCATION_IDS } from '../api';
import type { Equipment } from '../types';
import { StatusBadge } from './StatusBadge';

interface Props {
  selectedId: string | null;
  onSelect: (equipment: Equipment) => void;
}

/**
 * Equipment grouped by location.
 *
 * One query per location rather than one for all: the API has no "list
 * locations" endpoint, so the ids are seeded in api.ts and fetched in parallel.
 * The gap is real and documented in the README — this component works around it
 * rather than pretending it is not there.
 */
export function LocationPanel({ selectedId, onSelect }: Props) {
  const results = useQueries({
    queries: KNOWN_LOCATION_IDS.map((locationId) => ({
      queryKey: ['equipment', locationId],
      queryFn: () => api.equipmentAtLocation(locationId),
    })),
  });

  return (
    <section className="panel">
      <h2 className="panel-title">Asukohad</h2>

      {KNOWN_LOCATION_IDS.map((locationId, index) => {
        const result = results[index];
        return (
          <div key={locationId} className="stack">
            <div className="row-meta">{locationId}</div>

            {result?.isPending && <p className="note">Laen…</p>}

            {result?.error && (
              <p className="error">
                <strong>{locationId}</strong> {result.error.message}
              </p>
            )}

            {result?.data && result.data.length === 0 && (
              <p className="note">Selles asukohas seadmeid ei ole.</p>
            )}

            {result?.data && result.data.length > 0 && (
              <ul className="list">
                {result.data.map((equipment) => (
                  <li key={equipment.id}>
                    <button
                      type="button"
                      className="row"
                      aria-current={equipment.id === selectedId}
                      onClick={() => onSelect(equipment)}
                    >
                      <span className="row-main">
                        <span className="row-name">{equipment.name}</span>
                        <span className="row-meta">
                          {equipment.id} · {equipment.type}
                        </span>
                      </span>
                      <StatusBadge status={equipment.status} />
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        );
      })}
    </section>
  );
}
