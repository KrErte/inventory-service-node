import { useMemo, useState } from 'react';
import type { Connection, Equipment, ReachableEquipment } from '../types';

interface Props {
  root: Equipment;
  reachable: ReachableEquipment[];
  /** Active connections whose both ends are inside the reachable set. */
  edges: Connection[];
}

interface Node {
  id: string;
  name: string;
  type: string;
  status: Equipment['status'];
  depth: number;
  x: number;
  y: number;
}

const WIDTH = 640;
const HEIGHT = 520;
const CENTRE_X = WIDTH / 2;
const CENTRE_Y = HEIGHT / 2;
const OUTER_RADIUS = 205;
const NODE_RADIUS = 15;

/**
 * Ordinal blue ramp, validated against both surfaces: single hue, monotone
 * lightness, visible gaps between steps, and the step nearest the surface still
 * clears 2:1. Depth 1 is the lightest.
 */
const DEPTH_COLOURS = [
  'var(--depth-1)',
  'var(--depth-2)',
  'var(--depth-3)',
  'var(--depth-4)',
  'var(--depth-5)',
];

function depthColour(depth: number): string {
  const index = Math.min(depth, DEPTH_COLOURS.length) - 1;
  return DEPTH_COLOURS[index] ?? DEPTH_COLOURS[0]!;
}

/**
 * Concentric rings, one per hop.
 *
 * A force-directed layout would scatter these nodes by connectivity, which is
 * not what the endpoint answers — it answers *distance from a starting point*.
 * Putting distance on the radius makes the depth parameter legible at a glance:
 * move the slider and a ring appears. Angle carries nothing and is not meant to.
 */
export function DepthGraph({ root, reachable, edges }: Props) {
  const [hovered, setHovered] = useState<string | null>(null);

  const nodes = useMemo<Node[]>(() => {
    const maxDepth = reachable.reduce((max, item) => Math.max(max, item.depth), 0);
    const ringStep = OUTER_RADIUS / Math.max(maxDepth, 1);

    const byDepth = new Map<number, ReachableEquipment[]>();
    for (const item of reachable) {
      const bucket = byDepth.get(item.depth);
      if (bucket) bucket.push(item);
      else byDepth.set(item.depth, [item]);
    }

    const placed: Node[] = [
      {
        id: root.id,
        name: root.name,
        type: root.type,
        status: root.status,
        depth: 0,
        x: CENTRE_X,
        y: CENTRE_Y,
      },
    ];

    for (const [depth, items] of byDepth) {
      const radius = ringStep * depth;
      items.forEach((item, index) => {
        // Spread evenly around the ring, with each ring rotated a little
        // relative to the one inside it. Without the offset every ring starts at
        // twelve o'clock and a chain of single-node depths stacks into one
        // vertical line, with edges running through the nodes between them.
        // Angle carries no meaning, so rotating it costs nothing and the graph
        // reads as a fan instead of a column.
        const offset = -Math.PI / 2 + depth * 0.7;
        const angle = (index / items.length) * Math.PI * 2 + offset;
        placed.push({
          id: item.equipment.id,
          name: item.equipment.name,
          type: item.equipment.type,
          status: item.equipment.status,
          depth,
          x: CENTRE_X + Math.cos(angle) * radius,
          y: CENTRE_Y + Math.sin(angle) * radius,
        });
      });
    }

    return placed;
  }, [root, reachable]);

  const positions = useMemo(() => new Map(nodes.map((node) => [node.id, node])), [nodes]);

  const rings = useMemo(() => {
    const maxDepth = reachable.reduce((max, item) => Math.max(max, item.depth), 0);
    const ringStep = OUTER_RADIUS / Math.max(maxDepth, 1);
    return Array.from({ length: maxDepth }, (_, index) => ({
      depth: index + 1,
      radius: ringStep * (index + 1),
    }));
  }, [reachable]);

  const depthsPresent = useMemo(
    () => [...new Set(reachable.map((item) => item.depth))].sort((a, b) => a - b),
    [reachable],
  );

  const hoveredNode = hovered ? positions.get(hovered) : undefined;

  return (
    <div className="stack">
      <div className="graph-wrap">
        <svg
          className="graph"
          viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
          role="img"
          aria-label={`Seadmest ${root.name} aktiivsete ühenduste kaudu saavutatavad seadmed, rühmitatud sammude arvu järgi. Täpsed väärtused on tabelis allpool.`}
        >
          {rings.map((ring) => {
            // Labels sit on the upper-left diagonal: nodes start from twelve
            // o'clock and fan clockwise, so this is the quietest part of a ring.
            const labelAngle = (-3 * Math.PI) / 4;
            return (
              <g key={ring.depth}>
                <circle className="ring" cx={CENTRE_X} cy={CENTRE_Y} r={ring.radius} />
                <text
                  className="ring-label"
                  x={CENTRE_X + Math.cos(labelAngle) * ring.radius}
                  y={CENTRE_Y + Math.sin(labelAngle) * ring.radius}
                >
                  {ring.depth} samm{ring.depth === 1 ? '' : 'u'}
                </text>
              </g>
            );
          })}

          {edges.map((edge) => {
            const from = positions.get(edge.sourceEquipmentId);
            const to = positions.get(edge.targetEquipmentId);
            if (!from || !to) return null;
            return (
              <line
                key={edge.id}
                className="edge"
                x1={from.x}
                y1={from.y}
                x2={to.x}
                y2={to.y}
              />
            );
          })}

          {nodes.map((node) => (
            <g key={node.id}>
              <circle
                className={`node${node.status === 'INACTIVE' ? ' inactive' : ''}`}
                cx={node.x}
                cy={node.y}
                r={NODE_RADIUS}
                fill={node.depth === 0 ? 'var(--root-node)' : depthColour(node.depth)}
                onMouseEnter={() => setHovered(node.id)}
                onMouseLeave={() => setHovered(null)}
              />
              <text className="node-label" x={node.x} y={node.y} fill="var(--surface)">
                {node.id}
              </text>
            </g>
          ))}

          {hoveredNode && (
            <g transform={`translate(${hoveredNode.x + NODE_RADIUS + 8}, ${hoveredNode.y - 26})`}>
              <rect
                width={190}
                height={52}
                rx={3}
                fill="var(--surface)"
                stroke="var(--baseline)"
              />
              <text x={10} y={20} fill="var(--ink)" fontSize={12} fontWeight={600}>
                {hoveredNode.name}
              </text>
              <text x={10} y={38} fill="var(--ink-2)" fontSize={11}>
                {hoveredNode.type} ·{' '}
                {hoveredNode.depth === 0 ? 'algus' : `${hoveredNode.depth} sammu`} ·{' '}
                {hoveredNode.status === 'ACTIVE' ? 'aktiivne' : 'mitteaktiivne'}
              </text>
            </g>
          )}
        </svg>
      </div>

      <div className="legend">
        <span className="legend-item">
          <span className="legend-swatch" style={{ background: 'var(--root-node)' }} />
          Algus
        </span>
        {depthsPresent.map((depth) => (
          <span key={depth} className="legend-item">
            <span className="legend-swatch" style={{ background: depthColour(depth) }} />
            {depth} samm{depth === 1 ? '' : 'u'}
          </span>
        ))}
        <span className="legend-item">
          <span
            className="legend-swatch"
            style={{
              background: 'transparent',
              border: '1.5px dashed var(--muted)',
              borderRadius: '50%',
            }}
          />
          Katkendlik ääris = mitteaktiivne seade
        </span>
      </div>
    </div>
  );
}
