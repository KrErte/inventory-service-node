import { useQuery } from '@tanstack/react-query';
import { api } from '../api';

/**
 * Four counts and one proportion.
 *
 * Deliberately not a chart: each number is a single headline with no comparison
 * to make, and a bar chart of three unrelated totals would invite comparisons
 * that mean nothing. The one place a mark earns its keep is active vs inactive
 * connections, where the split is the point — a two-segment bar with both
 * values written out beneath it, so the mark supports the number rather than
 * replacing it.
 */
export function SummaryTiles() {
  const { data, isPending, error } = useQuery({
    queryKey: ['summary'],
    queryFn: api.summary,
  });

  if (isPending) return <p className="note">Laen kokkuvõtet…</p>;
  if (error) {
    return (
      <p className="error">
        <strong>Kokkuvõtet ei õnnestunud laadida.</strong> {error.message}
      </p>
    );
  }

  const totalConnections = data.activeConnectionCount + data.inactiveConnectionCount;
  const activeShare = totalConnections === 0 ? 0 : data.activeConnectionCount / totalConnections;

  return (
    <div className="tiles">
      <div className="tile">
        <span className="tile-label">Asukohti</span>
        <span className="tile-value">{data.locationCount}</span>
      </div>
      <div className="tile">
        <span className="tile-label">Seadmeid</span>
        <span className="tile-value">{data.equipmentCount}</span>
      </div>
      <div className="tile tile-wide">
        <span className="tile-label">Ühendusi</span>
        <span className="tile-value">{totalConnections}</span>
        <div
          className="proportion"
          role="img"
          aria-label={`${data.activeConnectionCount} aktiivset, ${data.inactiveConnectionCount} mitteaktiivset ühendust`}
        >
          <span className="active" style={{ width: `${activeShare * 100}%` }} />
          <span className="inactive" style={{ width: `${(1 - activeShare) * 100}%` }} />
        </div>
        <div className="proportion-key">
          <span className="legend-item">
            <span className="legend-swatch" style={{ background: 'var(--status-good)' }} />
            {data.activeConnectionCount} aktiivset
          </span>
          <span className="legend-item">
            <span className="legend-swatch" style={{ background: 'var(--baseline)' }} />
            {data.inactiveConnectionCount} mitteaktiivne
          </span>
        </div>
      </div>
    </div>
  );
}
