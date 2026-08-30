import type { ThemePreference } from '../useTheme';

const OPTIONS: { value: ThemePreference; label: string }[] = [
  { value: 'light', label: 'Hele' },
  { value: 'dark', label: 'Tume' },
  { value: 'system', label: 'Süsteem' },
];

interface Props {
  preference: ThemePreference;
  onChange: (preference: ThemePreference) => void;
}

export function ThemeToggle({ preference, onChange }: Props) {
  return (
    <div className="theme-toggle" role="group" aria-label="Värviteema">
      {OPTIONS.map((option) => (
        <button
          key={option.value}
          type="button"
          aria-pressed={preference === option.value}
          onClick={() => onChange(option.value)}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}
