import { useMemo, useState } from 'react';
import { useQueries, useQuery } from '@tanstack/react-query';
import { api } from '../api';
import type { Connection, Equipment } from '../types';
import { DepthGraph } from './DepthGraph';
import { StatusBadge } from './StatusBadge';

const MAX_DEPTH = 5;

export function EquipmentDetail({ equipment }: { equipment: Equipment }) {
  const [depth, setDepth] = useState(1);

  const connections = useQuery({
    queryKey: ['connections', equipment.id],
    queryFn: () => api.connectionsFor(equipment.id),
  });

  const connected = useQuery({
    queryKey: ['connected', equipment.id, depth],
    queryFn: () => api.connectedFrom(equipment.id, depth),
  });

  const reachable = useMemo(() => connected.data ?? [], [connected.data]);

  /**
   * Edges for the graph.
   *
   * The API answers "which equipment is reachable" but not "how they are wired
   * to each other", so drawing truthful edges means asking each reachable node
   * for its own connections. That is an N+1 — fine for a dataset this size, and
   * TanStack Query dedupes and caches it, but a production API would answer the
   * whole subgraph in one call. Noted in the README rather than hidden.
   */
  const neighbourQueries = useQueries({
    queries: reachable.map((item) => ({
      queryKey: ['connections', item.equipment.id],
      queryFn: () => api.connectionsFor(item.equipment.id),
    })),
  });

  const edges = useMemo<Connection[]>(() => {
    const known = new Set<string>([equipment.id, ...reachable.map((item) => item.equipment.id)]);
    const byId = new Map<string, Connection>();

    const all = [connections.data ?? [], ...neighbourQueries.map((query) => query.data ?? [])];
    for (const batch of all) {
      for (const connection of batch) {
        if (connection.status !== 'ACTIVE') continue;
        if (!known.has(connection.sourceEquipmentId)) continue;
        if (!known.has(connection.targetEquipmentId)) continue;
        byId.set(connection.id, connection);
      }
    }
    return [...byId.values()];
  }, [equipment.id, reachable, connections.data, neighbourQueries]);

  return (
    <div className="stack">
      <section className="panel">
        <h2 className="panel-title">Valitud seade</h2>
        <div className="control" style={{ justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: '1.15rem', fontWeight: 600 }}>{equipment.name}</div>
            <div className="row-meta">
              {equipment.id} · {equipment.type} · {equipment.locationId}
            </div>
          </div>
          <StatusBadge status={equipment.status} />
        </div>
      </section>

      <section className="panel">
        <h2 className="panel-title">Ühendused</h2>
        {connections.isPending && <p className="note">Laen…</p>}
        {connections.error && (
          <p className="error">
            <strong>Ühendusi ei õnnestunud laadida.</strong> {connections.error.message}
          </p>
        )}
        {connections.data && connections.data.length === 0 && (
          <p className="note">Sellel seadmel ühendusi ei ole.</p>
        )}
        {connections.data && connections.data.length > 0 && (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Ühendus</th>
                  <th>Allikas</th>
                  <th>Sihtkoht</th>
                  <th>Olek</th>
                </tr>
              </thead>
              <tbody>
                {connections.data.map((connection) => (
                  <tr key={connection.id}>
                    <td>{connection.id}</td>
                    <td>{connection.sourceEquipmentId}</td>
                    <td>{connection.targetEquipmentId}</td>
                    <td>
                      <StatusBadge status={connection.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <section className="panel">
        <h2 className="panel-title">Saavutatavad seadmed</h2>

        <div className="control">
          <label htmlFor="depth">Sügavus</label>
          <input
            id="depth"
            type="range"
            min={0}
            max={MAX_DEPTH}
            step={1}
            value={depth}
            onChange={(event) => setDepth(Number(event.target.value))}
          />
          <output htmlFor="depth">{depth}</output>
        </div>

        <p className="note">
          Läbitakse ainult aktiivseid ühendusi. Seadme enda olek liikumist ei takista — seda
          teeb ainult ühenduse olek.
        </p>

        {connected.isPending && <p className="note">Laen…</p>}
        {connected.error && (
          <p className="error">
            <strong>Läbimine ebaõnnestus.</strong> {connected.error.message}
          </p>
        )}

        {connected.data && connected.data.length === 0 && (
          <p className="note">
            {depth === 0
              ? 'Sügavusel 0 ei ole midagi saavutatav — see on määratluse järgi tühi.'
              : 'Ükski seade ei ole selle sügavusega saavutatav.'}
          </p>
        )}

        {connected.data && connected.data.length > 0 && (
          <>
            <DepthGraph root={equipment} reachable={reachable} edges={edges} />

            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Seade</th>
                    <th>Nimi</th>
                    <th>Tüüp</th>
                    <th>Samme</th>
                    <th>Olek</th>
                  </tr>
                </thead>
                <tbody>
                  {reachable.map((item) => (
                    <tr key={item.equipment.id}>
                      <td>{item.equipment.id}</td>
                      <td>{item.equipment.name}</td>
                      <td>{item.equipment.type}</td>
                      <td className="num">{item.depth}</td>
                      <td>
                        <StatusBadge status={item.equipment.status} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </section>
    </div>
  );
}
