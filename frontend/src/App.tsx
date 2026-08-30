import { useState } from 'react';
import { LocationPanel } from './components/LocationPanel';
import { EquipmentDetail } from './components/EquipmentDetail';
import { SummaryTiles } from './components/SummaryTiles';
import { ThemeToggle } from './components/ThemeToggle';
import { useTheme } from './useTheme';
import type { Equipment } from './types';

export default function App() {
  const [selected, setSelected] = useState<Equipment | null>(null);
  const { preference, choose } = useTheme();

  return (
    <div className="app">
      <header className="app-head">
        <div>
          <h1>Inventory Service</h1>
          <p className="sub">Pharo Smalltalk backend · React frontend</p>
        </div>
        <div className="head-right">
          <ThemeToggle preference={preference} onChange={choose} />
          <p className="sub">API: /api/v1</p>
        </div>
      </header>

      <SummaryTiles />

      <div className="columns">
        <LocationPanel selectedId={selected?.id ?? null} onSelect={setSelected} />

        {selected ? (
          <EquipmentDetail key={selected.id} equipment={selected} />
        ) : (
          <section className="panel">
            <h2 className="panel-title">Seade</h2>
            <p className="note">
              Vali vasakult seade, et näha selle ühendusi ja aktiivsete ühenduste kaudu
              saavutatavaid seadmeid.
            </p>
          </section>
        )}
      </div>
    </div>
  );
}
