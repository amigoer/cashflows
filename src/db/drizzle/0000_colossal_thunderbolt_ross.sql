CREATE TABLE `debt_plans` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`platform` text NOT NULL,
	`principal_cents` integer NOT NULL,
	`total_periods` integer NOT NULL,
	`monthly_payment_cents` integer NOT NULL,
	`first_due_date` integer NOT NULL,
	`apr_bps` integer DEFAULT 0 NOT NULL,
	`note` text,
	`archived` integer DEFAULT false NOT NULL,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `repayments` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`debt_plan_id` integer NOT NULL,
	`period_index` integer NOT NULL,
	`due_date` integer NOT NULL,
	`amount_cents` integer NOT NULL,
	`status` text DEFAULT 'pending' NOT NULL,
	`paid_at` integer,
	FOREIGN KEY (`debt_plan_id`) REFERENCES `debt_plans`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `salaries` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`amount_cents` integer NOT NULL,
	`paid_at` integer NOT NULL,
	`period` text DEFAULT 'monthly' NOT NULL,
	`note` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
