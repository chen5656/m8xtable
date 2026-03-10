type GridSize = 3 | 4 | 6;
type LayoutSpan = [colSpan: number, rowSpan: number];

const TILE_SIZES = {
  small: { colSpan: 1, rowSpan: 1 },
  wide: { colSpan: 2, rowSpan: 1 },
  tall: { colSpan: 1, rowSpan: 2 },
  hero: { colSpan: 2, rowSpan: 2 },
  feature: { colSpan: 3, rowSpan: 2 },
  panorama: { colSpan: 3, rowSpan: 1 },
  poster: { colSpan: 2, rowSpan: 3 },
  cinema: { colSpan: 4, rowSpan: 2 },
} as const;

type TileType = keyof typeof TILE_SIZES;
type RNG = () => number;

/**
 * Pure function:
 * - no side effect
 * - same input => same output
 * - source order stays unchanged
 */
export function updateRecipeListLayout(
  size: GridSize,
  pictureCount: number,
  seed: string | number,
): LayoutSpan[] {
  if (![3, 4, 6].includes(size)) {
    throw new Error(`Invalid size: ${size}. Expected 3 | 4 | 6.`);
  }

  if (!Number.isInteger(pictureCount) || pictureCount < 0) {
    throw new Error(`Invalid pictureCount: ${pictureCount}. Expected integer >= 0.`);
  }

  if (pictureCount === 0) {
    return [];
  }

  const chunkSizes = partitionPictureCount(size, pictureCount);

  // 全局候选搜索：同一个 seed 下做少量 deterministic search，
  // 选一个更整齐、内部洞更少的方案。
  const candidateCount = pictureCount <= 24 ? 16 : 10;

  let bestPlan: TileType[] = [];
  let bestScore = Number.POSITIVE_INFINITY;

  for (let candidateIndex = 0; candidateIndex < candidateCount; candidateIndex += 1) {
    const candidateTypes: TileType[] = [];

    for (let chunkIndex = 0; chunkIndex < chunkSizes.length; chunkIndex += 1) {
      const chunkCount = chunkSizes[chunkIndex];
      const chunkSeed = `${seed}|size:${size}|count:${pictureCount}|candidate:${candidateIndex}|chunk:${chunkIndex}`;
      const chunk = buildChunk(size, chunkCount, chunkSeed);
      candidateTypes.push(...chunk);
    }

    const score = scoreLayout(size, candidateTypes);

    if (score < bestScore) {
      bestScore = score;
      bestPlan = candidateTypes;
    }
  }

  return bestPlan.map((type) => {
    const tile = TILE_SIZES[type];
    return [tile.colSpan, tile.rowSpan];
  });
}

/* ---------------------------------- */
/* partition                          */
/* ---------------------------------- */

function partitionPictureCount(size: GridSize, total: number): number[] {
  if (size === 3) {
    return partitionMobile(total);
  }
  if (size === 4) {
    return partitionTablet(total);
  }
  return partitionDesktop(total);
}

// 手机：基本节奏 6，尾巴尽量不要留下 1 / 2 这种很丑的小尾巴
function partitionMobile(total: number): number[] {
  if (total <= 6) {
    return [total];
  }

  const full = Math.floor(total / 6);
  const rem = total % 6;
  const result = Array.from({ length: full }, () => 6);

  if (rem === 0) {
    return result;
  }

  if (rem >= 3) {
    result.push(rem);
    return result;
  }

  // rem = 1 or 2，借一个 6 出来平滑尾巴
  result.pop();

  if (rem === 1) {
    result.push(4, 3); // 7 => 4 + 3
  } else {
    result.push(5, 3); // 8 => 5 + 3
  }

  return result;
}

// 平板：基本节奏 8，同样避免特别丑的小尾巴
function partitionTablet(total: number): number[] {
  if (total <= 8) {
    return [total];
  }

  const full = Math.floor(total / 8);
  const rem = total % 8;
  const result = Array.from({ length: full }, () => 8);

  if (rem === 0) {
    return result;
  }

  if (rem >= 5) {
    result.push(rem);
    return result;
  }

  // rem = 1..4，做平滑
  if (rem === 1 && result.length >= 2) {
    result.pop();
    result.pop();
    result.push(6, 6, 5); // 17 => 6 + 6 + 5
    return result;
  }

  if (rem === 2 && result.length >= 2) {
    result.pop();
    result.pop();
    result.push(6, 6, 6); // 18 => 6 + 6 + 6
    return result;
  }

  result.pop();

  if (rem === 1) {
    result.push(4, 5); // 9 => 4 + 5
  } else if (rem === 2) {
    result.push(5, 5); // 10 => 5 + 5
  } else if (rem === 3) {
    result.push(6, 5); // 11 => 6 + 5
  } else {
    result.push(6, 6); // 12 => 6 + 6
  }

  return result;
}

// 桌面：理想是 10~12，但为了避免奇怪尾巴，允许 8~15 作为平滑 chunk
function partitionDesktop(total: number): number[] {
  if (total <= 15) {
    return [total];
  }

  const allowed = [8, 9, 10, 11, 12, 13, 14, 15];
  const dp = Array<number>(total + 1).fill(Number.POSITIVE_INFINITY);
  const prev = Array<number>(total + 1).fill(-1);

  dp[0] = 0;

  for (let i = 1; i <= total; i += 1) {
    for (const s of allowed) {
      if (i < s || !Number.isFinite(dp[i - s])) {
        continue;
      }

      const candidate = dp[i - s] + desktopChunkPenalty(s) + 2; // +2 稍微压缩 chunk 数量

      if (candidate < dp[i]) {
        dp[i] = candidate;
        prev[i] = s;
      }
    }
  }

  if (!Number.isFinite(dp[total])) {
    return [total];
  }

  const result: number[] = [];
  let cur = total;

  while (cur > 0) {
    const step = prev[cur];
    if (step <= 0) {
      return [total];
    }
    result.push(step);
    cur -= step;
  }

  return result.reverse();
}

function desktopChunkPenalty(size: number): number {
  switch (size) {
    case 10:
    case 11:
      return 0;
    case 12:
      return 1;
    case 13:
      return 3;
    case 9:
      return 5;
    case 14:
      return 7;
    case 8:
      return 10;
    case 15:
      return 12;
    default:
      return 20;
  }
}

/* ---------------------------------- */
/* chunk builder                      */
/* ---------------------------------- */

function buildChunk(size: GridSize, count: number, seed: string): TileType[] {
  const rng = createRng(seed);

  if (size === 3) {
    return buildMobileChunk(count, rng);
  }
  if (size === 4) {
    return buildTabletChunk(count, rng);
  }
  return buildDesktopChunk(count, rng);
}

function buildMobileChunk(count: number, rng: RNG): TileType[] {
  if (count <= 0) return [];
  if (count === 1) return ['small'];
  if (count === 2) return buildFromRoles(3, 2, ['wide'], rng);
  if (count === 3) return buildFromRoles(3, 3, ['hero'], rng);

  // 尾巴平滑：4 / 5 单独处理，尽量让面积更整齐
  if (count === 4) {
    const roles = pickOne(rng, [
      ['wide', 'wide'],
      ['tall', 'tall'],
    ] as TileType[][]);
    return buildFromRoles(3, 4, roles, rng);
  }

  if (count === 5) {
    const roles = pickOne(rng, [
      ['hero', 'wide'],
      ['hero', 'tall'],
    ] as TileType[][]);
    return buildFromRoles(3, 5, roles, rng);
  }

  // 每 6 张：1 个 hero / wide / tall，其余 small
  const standout = pickWeighted<TileType>(rng, [
    ['hero', 0.45],
    ['wide', 0.30],
    ['tall', 0.25],
  ]);

  return buildFromRoles(3, count, [standout], rng);
}

function buildTabletChunk(count: number, rng: RNG): TileType[] {
  if (count <= 0) return [];
  if (count === 1) return ['small'];
  if (count === 2) return buildFromRoles(4, 2, ['wide'], rng);
  if (count === 3) return buildFromRoles(4, 3, ['wide'], rng);

  if (count === 4) {
    const roles = rng() < 0.35 ? (['hero'] as TileType[]) : [];
    return buildFromRoles(4, 4, roles, rng);
  }

  if (count === 5) {
    return buildFromRoles(4, 5, ['hero'], rng);
  }

  if (count === 6) {
    const roles = pickOne(rng, [
      ['wide', 'wide'],
      ['wide', 'tall'],
      ['tall', 'tall'],
      ['hero', 'wide'],
    ] as TileType[][]);
    return buildFromRoles(4, 6, roles, rng);
  }

  if (count === 7) {
    const roles = pickOne(rng, [
      ['feature'],
      ['hero', 'wide'],
      ['hero', 'tall'],
    ] as TileType[][]);
    return buildFromRoles(4, 7, roles, rng);
  }

  // 8+：至少 1 个 hero/feature，1~2 个 wide/tall
  {
    const roles: TileType[] = [];
    const main = rng() < 0.65 ? 'hero' : 'feature';
    roles.push(main);

    const accentCount = count >= 10 ? randInt(rng, 1, 2) : randInt(rng, 1, 2);
    for (let i = 0; i < accentCount; i += 1) {
      roles.push(pickAccent(rng));
    }

    return buildFromRoles(4, count, roles, rng);
  }
}

function buildDesktopChunk(count: number, rng: RNG): TileType[] {
  if (count <= 0) return [];
  if (count === 1) return ['small'];
  if (count === 2) return buildFromRoles(6, 2, ['wide'], rng);
  if (count === 3) return buildFromRoles(6, 3, ['wide'], rng);

  if (count === 4) {
    const roles = pickOne(rng, [
      ['wide', 'wide'],
      ['hero'],
    ] as TileType[][]);
    return buildFromRoles(6, 4, roles, rng);
  }

  if (count === 5) {
    const roles = pickOne(rng, [
      ['hero', 'wide'],
      ['wide', 'wide'],
    ] as TileType[][]);
    return buildFromRoles(6, 5, roles, rng);
  }

  if (count === 6) {
    const roles = pickOne(rng, [
      ['hero', 'wide'],
      ['hero', 'tall'],
      ['feature'],
    ] as TileType[][]);
    return buildFromRoles(6, 6, roles, rng);
  }

  if (count === 7) {
    const roles = pickOne(rng, [
      ['hero', 'wide', 'wide'],
      ['hero', 'wide', 'tall'],
      ['feature', 'wide'],
    ] as TileType[][]);
    return buildFromRoles(6, 7, roles, rng);
  }

  if (count === 8) {
    const roles = pickOne(rng, [
      ['feature', 'hero', pickAccent(rng)],
      ['feature', pickAccent(rng), pickAccent(rng)],
      ['cinema', pickAccent(rng)],
    ] as TileType[][]);
    return buildFromRoles(6, 8, roles, rng);
  }

  if (count === 9) {
    const roles = pickOne(rng, [
      ['feature', 'hero', pickAccent(rng), pickAccent(rng)],
      ['cinema', pickAccent(rng), pickAccent(rng)],
      ['feature', pickAccent(rng), pickAccent(rng), pickAccent(rng)],
    ] as TileType[][]);
    return buildFromRoles(6, 9, roles, rng);
  }

  // 10~12（以及平滑尾巴 13~15）：
  // 1 个 feature/cinema
  // 1 个 hero/poster
  // 2~3 个 wide/tall
  {
    const roles: TileType[] = [];

    roles.push(rng() < 0.35 ? 'cinema' : 'feature');
    roles.push(rng() < 0.30 ? 'poster' : 'hero');

    const accentCount = count >= 11 ? randInt(rng, 2, 3) : 2;
    for (let i = 0; i < accentCount; i += 1) {
      roles.push(pickAccent(rng));
    }

    return buildFromRoles(6, count, roles, rng);
  }
}

/* ---------------------------------- */
/* role arrangement                   */
/* ---------------------------------- */

function buildFromRoles(
  columns: GridSize,
  itemCount: number,
  roles: readonly TileType[],
  rng: RNG,
): TileType[] {
  const base: TileType[] = Array.from({ length: itemCount }, () => 'small');

  if (roles.length === 0) {
    return base;
  }

  // 同一组 roles 做几个 deterministic 尝试，选更整齐的
  let best = base;
  let bestScore = Number.POSITIVE_INFINITY;
  const attempts = Math.max(8, roles.length * 4);

  for (let i = 0; i < attempts; i += 1) {
    const slotRng = createRng(`${Math.floor(rng() * 1_000_000_000)}|slots|${i}`);
    const roleRng = createRng(`${Math.floor(rng() * 1_000_000_000)}|roles|${i}`);

    const candidate: TileType[] = Array.from({ length: itemCount }, () => 'small');
    const indices = pickSpreadIndices(itemCount, roles.length, slotRng);
    const arrangedRoles = shuffle([...roles], roleRng);

    for (let idx = 0; idx < indices.length; idx += 1) {
      candidate[indices[idx]] = arrangedRoles[idx];
    }

    const score = scoreLayout(columns, candidate);
    if (score < bestScore) {
      bestScore = score;
      best = candidate;
    }
  }

  return best;
}

function pickSpreadIndices(total: number, count: number, rng: RNG): number[] {
  if (count <= 0) return [];
  if (count >= total) {
    return Array.from({ length: total }, (_, i) => i);
  }

  const used = Array.from({ length: total }, () => false);
  const result: number[] = [];
  const gap = total / count;
  const jitter = Math.max(1, Math.floor(gap / 3));

  for (let i = 0; i < count; i += 1) {
    const center = (i + 0.5) * gap - 0.5;
    let index = Math.round(center) + randInt(rng, -jitter, jitter);
    index = clamp(index, 0, total - 1);

    while (used[index]) {
      index = (index + 1) % total;
    }

    used[index] = true;
    result.push(index);
  }

  return result.sort((a, b) => a - b);
}

/* ---------------------------------- */
/* scoring / dense simulation         */
/* ---------------------------------- */

function scoreLayout(columns: GridSize, tiles: readonly TileType[]): number {
  if (tiles.length === 0) {
    return 0;
  }

  const occupied: boolean[][] = [];
  let usedRows = 0;

  const ensureRows = (rowCount: number): void => {
    while (occupied.length < rowCount) {
      occupied.push(Array.from({ length: columns }, () => false));
    }
  };

  const canPlace = (
    row: number,
    col: number,
    colSpan: number,
    rowSpan: number,
  ): boolean => {
    if (col + colSpan > columns) {
      return false;
    }

    ensureRows(row + rowSpan);

    for (let r = row; r < row + rowSpan; r += 1) {
      for (let c = col; c < col + colSpan; c += 1) {
        if (occupied[r][c]) {
          return false;
        }
      }
    }

    return true;
  };

  const place = (
    row: number,
    col: number,
    colSpan: number,
    rowSpan: number,
  ): void => {
    ensureRows(row + rowSpan);

    for (let r = row; r < row + rowSpan; r += 1) {
      for (let c = col; c < col + colSpan; c += 1) {
        occupied[r][c] = true;
      }
    }

    usedRows = Math.max(usedRows, row + rowSpan);
  };

  // 模拟 CSS grid-auto-flow: dense 的“尽量补洞”
  for (const type of tiles) {
    const { colSpan, rowSpan } = TILE_SIZES[type];
    let placed = false;

    for (let row = 0; row <= usedRows; row += 1) {
      for (let col = 0; col <= columns - colSpan; col += 1) {
        if (canPlace(row, col, colSpan, rowSpan)) {
          place(row, col, colSpan, rowSpan);
          placed = true;
          break;
        }
      }
      if (placed) {
        break;
      }
    }

    if (!placed) {
      throw new Error(`Failed to place tile: ${type}`);
    }
  }

  let internalHoles = 0;
  let lastRowHoles = 0;
  let roughness = 0;
  let prevFilled: number | null = null;

  for (let row = 0; row < usedRows; row += 1) {
    const cells = occupied[row] ?? Array.from({ length: columns }, () => false);
    const filled = cells.reduce((sum, cell) => sum + (cell ? 1 : 0), 0);
    const empty = columns - filled;

    if (row < usedRows - 1) {
      internalHoles += empty;
    } else {
      lastRowHoles += empty;
    }

    if (prevFilled !== null) {
      roughness += Math.abs(prevFilled - filled);
    }
    prevFilled = filled;
  }

  // 内部洞权重大，最后一行的空缺权重小一点
  return internalHoles * 100 + lastRowHoles * 10 + roughness + usedRows;
}

/* ---------------------------------- */
/* utils                              */
/* ---------------------------------- */

function pickAccent(rng: RNG): TileType {
  return rng() < 0.5 ? 'wide' : 'tall';
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function randInt(rng: RNG, min: number, max: number): number {
  return Math.floor(rng() * (max - min + 1)) + min;
}

function pickOne<T>(rng: RNG, values: readonly T[]): T {
  return values[randInt(rng, 0, values.length - 1)];
}

function pickWeighted<T>(
  rng: RNG,
  entries: ReadonlyArray<readonly [T, number]>,
): T {
  const total = entries.reduce((sum, [, weight]) => sum + weight, 0);
  let value = rng() * total;

  for (const [item, weight] of entries) {
    value -= weight;
    if (value <= 0) {
      return item;
    }
  }

  return entries[entries.length - 1][0];
}

function shuffle<T>(items: T[], rng: RNG): T[] {
  const result = [...items];

  for (let i = result.length - 1; i > 0; i -= 1) {
    const j = randInt(rng, 0, i);
    [result[i], result[j]] = [result[j], result[i]];
  }

  return result;
}

function createRng(seed: string | number): RNG {
  let state = hashSeed(seed);

  return () => {
    state += 0x6d2b79f5;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function hashSeed(seed: string | number): number {
  const text = String(seed);
  let h = 2166136261;

  for (let i = 0; i < text.length; i += 1) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }

  return h >>> 0 || 0x9e3779b9;
}