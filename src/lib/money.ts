const CENTS_PER_UNIT = 100;

const yuanFormatter = new Intl.NumberFormat('zh-CN', {
  style: 'decimal',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const compactFormatter = new Intl.NumberFormat('zh-CN', {
  notation: 'compact',
  maximumFractionDigits: 1,
});

export type FormatMoneyOptions = {
  showSymbol?: boolean;
  signed?: boolean;
  compact?: boolean;
};

export function formatMoney(cents: number, options: FormatMoneyOptions = {}): string {
  const { showSymbol = true, signed = false, compact = false } = options;

  const yuan = cents / CENTS_PER_UNIT;
  const absYuan = Math.abs(yuan);

  const body = compact ? compactFormatter.format(absYuan) : yuanFormatter.format(absYuan);

  const sign = signed ? (yuan >= 0 ? '+' : '-') : yuan < 0 ? '-' : '';
  const symbol = showSymbol ? '¥' : '';

  return `${sign}${symbol}${body}`;
}

export function parseMoneyToCents(input: string): number | null {
  const trimmed = input.replace(/[¥,\s元]/g, '').trim();
  if (trimmed.length === 0) return null;
  const num = Number(trimmed);
  if (!Number.isFinite(num)) return null;
  return Math.round(num * CENTS_PER_UNIT);
}

export function centsToYuan(cents: number): number {
  return cents / CENTS_PER_UNIT;
}

export function yuanToCents(yuan: number): number {
  return Math.round(yuan * CENTS_PER_UNIT);
}
