import { drizzle } from 'drizzle-orm/expo-sqlite';
import { openDatabaseSync } from 'expo-sqlite';

import * as schema from './schema';

const sqliteDb = openDatabaseSync('cashflows.db');

sqliteDb.execSync('PRAGMA foreign_keys = ON;');

export const db = drizzle(sqliteDb, { schema, logger: __DEV__ });

export { sqliteDb };
export type Database = typeof db;
