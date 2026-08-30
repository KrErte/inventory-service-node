import { useCallback, useEffect, useState } from 'react';

export type ThemePreference = 'system' | 'light' | 'dark';

const STORAGE_KEY = 'inventory.theme';

function read(): ThemePreference {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'light' || stored === 'dark' || stored === 'system') return stored;
  } catch {
    // Private mode, blocked site data — fall through to the default.
  }
  return 'system';
}

/**
 * Theme preference, stamped onto the root element as `data-theme`.
 *
 * Three states, not two. 'system' removes the attribute entirely and lets
 * prefers-color-scheme decide, which is what the stylesheet's media query
 * handles; 'light' and 'dark' stamp an explicit value that beats the OS setting
 * in both directions. Stamping "light" is not the same as stamping nothing —
 * that is the difference between "I want light" and "follow my machine".
 */
export function useTheme() {
  const [preference, setPreference] = useState<ThemePreference>(read);

  useEffect(() => {
    const root = document.documentElement;
    if (preference === 'system') {
      root.removeAttribute('data-theme');
    } else {
      root.dataset.theme = preference;
    }
    try {
      localStorage.setItem(STORAGE_KEY, preference);
    } catch {
      // Not being able to remember the choice is not a reason to fail applying it.
    }
  }, [preference]);

  const choose = useCallback((next: ThemePreference) => setPreference(next), []);

  return { preference, choose };
}
