import type { Status } from '../types';

/**
 * Status is never carried by colour alone: the dot is filled for active and a
 * hollow ring for inactive, and the word is always present beside it.
 */
export function StatusBadge({ status }: { status: Status }) {
  const active = status === 'ACTIVE';
  return (
    <span className={`badge ${active ? 'is-active' : 'is-inactive'}`}>
      <span className="dot" aria-hidden="true" />
      {active ? 'Aktiivne' : 'Mitteaktiivne'}
    </span>
  );
}
