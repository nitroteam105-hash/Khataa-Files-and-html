/**
 * Khaata PG / Hostel V1 — Mobile Query & Projection Layer v1
 *
 * STATUS: PROPOSED IMPLEMENTATION READ LAYER.
 *
 * Reads come from SQLite projections. UI never needs Supabase for normal screens.
 * Home attention is derived from state; there is no generic reminder/dismiss table.
 */

export type UUID = string;
export type Minor = number;
export type ISODate = string;
export type ISODateTime = string;

export interface QueryDb {
  get<T>(sql: string, params?: unknown[]): Promise<T | undefined>;
  all<T>(sql: string, params?: unknown[]): Promise<T[]>;
}

export interface BusinessPulse {
  collectedMinor: Minor;
  outstandingMinor: Minor;
  vacantBeds: number | null; // null means unknown, never show as zero
  becomingVacantThisMonth: number;
}

export type AttentionSeverity = "urgent" | "actionable" | "contextual";

export interface AttentionItem {
  type: string;
  severity: AttentionSeverity;
  entityType: string;
  entityId: UUID;
  relevantDate?: ISODate;
  amountMinor?: Minor;
}

export interface ComingUpItem {
  type: "joining" | "move_out" | "rent_due";
  entityType: "tenancy" | "obligation";
  entityId: UUID;
  eventDate: ISODate;
}

export interface HomeProjection {
  needsAttention: AttentionItem[];
  comingUp: ComingUpItem[];
  pulse: BusinessPulse;
}

export interface TenantListRow {
  tenancyId: UUID;
  tenantName: string;
  lifecycleState: "upcoming" | "active" | "planned_move_out" | "moved_out" | "cancelled_before_joining";
  roomLabel?: string;
  bedLabel?: string;
  operationalException?: {
    kind: "overdue" | "joining_overdue" | "refund_pending" | "approval_waiting";
    label: string;
    amountMinor?: Minor;
  };
}

export interface TenantDetailProjection {
  tenancyId: UUID;
  tenantName: string;
  lifecycleState: string;
  roomLabel?: string;
  bedLabel?: string;
  outstandingMinor: Minor;
  currentMonth: Array<{
    obligationId: UUID;
    dueDate?: ISODate;
    amountMinor: Minor;
    outstandingMinor: Minor;
  }>;
  recentPayments: Array<{
    paymentId: UUID;
    amountMinor: Minor;
    method?: string;
    occurredAt: ISODateTime;
    eventType: string;
  }>;
  security: {
    agreedMinor: Minor;
    heldMinor: Minor;
  } | null;
}

export interface CollectionRow {
  obligationId: UUID;
  tenancyId: UUID;
  tenantName: string;
  dueDate?: ISODate;
  amountMinor: Minor;
  outstandingMinor: Minor;
  settledMinor: Minor;
  state: "settled" | "part_paid" | "due" | "overdue";
}

export class HomeQueries {
  constructor(private db: QueryDb) {}

  async getHome(businessId: UUID): Promise<HomeProjection> {
    const pulseRow = await this.db.get<{
      collected_minor: number;
      outstanding_minor: number;
      vacant_beds: number | null;
      becoming_vacant_this_month: number;
    }>(
      `select collected_minor,outstanding_minor,vacant_beds,becoming_vacant_this_month
       from v_business_pulse where business_id=?`,
      [businessId]
    );

    const attentionRows = await this.db.all<{
      attention_type: string;
      severity: AttentionSeverity;
      entity_id: UUID;
      entity_type: string;
      relevant_date?: ISODate;
      amount_minor?: number;
    }>(
      `select attention_type,severity,entity_id,entity_type,relevant_date,amount_minor
       from v_attention_candidates
       where business_id=?
       order by case severity when 'urgent' then 0 else 1 end,
                relevant_date asc`,
      [businessId]
    );

    const comingRows = await this.db.all<{
      item_type: ComingUpItem["type"];
      entity_id: UUID;
      entity_type: ComingUpItem["entityType"];
      event_date: ISODate;
    }>(
      `select item_type,entity_id,entity_type,event_date
       from v_coming_up
       where business_id=?
       order by event_date asc`,
      [businessId]
    );

    return {
      needsAttention: attentionRows.map(r => ({
        type: r.attention_type,
        severity: r.severity,
        entityType: r.entity_type,
        entityId: r.entity_id,
        relevantDate: r.relevant_date,
        amountMinor: r.amount_minor
      })),
      comingUp: comingRows.map(r => ({
        type: r.item_type,
        entityType: r.entity_type,
        entityId: r.entity_id,
        eventDate: r.event_date
      })),
      pulse: {
        collectedMinor: pulseRow?.collected_minor ?? 0,
        outstandingMinor: pulseRow?.outstanding_minor ?? 0,
        vacantBeds: pulseRow?.vacant_beds ?? null,
        becomingVacantThisMonth: pulseRow?.becoming_vacant_this_month ?? 0
      }
    };
  }
}

export class TenantQueries {
  constructor(private db: QueryDb) {}

  async list(
    businessId: UUID,
    filter: "active" | "upcoming" | "moving_out" | "former" = "active",
    search?: string
  ): Promise<TenantListRow[]> {
    const stateMap: Record<string,string[]> = {
      active: ["active"],
      upcoming: ["upcoming"],
      moving_out: ["planned_move_out"],
      former: ["moved_out"]
    };
    const states = stateMap[filter];
    const placeholders = states.map(() => "?").join(",");
    const params: unknown[] = [businessId, ...states];
    let where = `business_id=? and lifecycle_state in (${placeholders})`;

    if (search?.trim()) {
      where += ` and lower(tenant_name) like ?`;
      params.push(`%${search.trim().toLowerCase()}%`);
    }

    const rows = await this.db.all<any>(
      `select * from v_tenant_rows where ${where} order by tenant_name collate nocase`,
      params
    );

    return Promise.all(rows.map(async (r: any) => {
      const exception = await this.primaryException(r.tenancy_id, r.outstanding_minor, r.planned_join_date);
      return {
        tenancyId: r.tenancy_id,
        tenantName: r.tenant_name ?? "Unnamed tenant",
        lifecycleState: r.lifecycle_state,
        roomLabel: r.room_label ?? undefined,
        bedLabel: r.bed_label ?? undefined,
        operationalException: exception
      };
    }));
  }

  private async primaryException(
    tenancyId: UUID,
    outstandingMinor: Minor,
    plannedJoinDate?: ISODate
  ): Promise<TenantListRow["operationalException"]> {
    const urgent = await this.db.get<any>(
      `select attention_type,amount_minor
       from v_attention_candidates
       where entity_type='tenancy' and entity_id=?
       order by case severity when 'urgent' then 0 else 1 end limit 1`,
      [tenancyId]
    );
    if (urgent) {
      return {
        kind: urgent.attention_type === "joining_overdue" ? "joining_overdue" : "overdue",
        label: urgent.attention_type.replaceAll("_"," "),
        amountMinor: urgent.amount_minor ?? undefined
      };
    }
    if (outstandingMinor > 0) {
      return { kind: "overdue", label: "Outstanding", amountMinor: outstandingMinor };
    }
    return undefined;
  }

  async detail(businessId: UUID, tenancyId: UUID): Promise<TenantDetailProjection | null> {
    const row = await this.db.get<any>(
      `select * from v_tenant_rows where business_id=? and tenancy_id=?`,
      [businessId, tenancyId]
    );
    if (!row) return null;

    const currentMonth = await this.db.all<any>(
      `select obligation_id,due_date,amount_minor,outstanding_minor
       from v_current_month_collections where business_id=? and tenancy_id=?
       order by due_date`,
      [businessId, tenancyId]
    );

    const recent = await this.db.all<any>(
      `select payment_id,amount_minor,payment_method,occurred_at,event_type
       from v_recent_payments where business_id=? and tenancy_id=?
       limit 20`,
      [businessId, tenancyId]
    );

    const security = await this.db.get<any>(
      `select sa.agreed_amount_minor,vsb.held_amount_minor
       from security_accounts sa
       join v_security_balances vsb on vsb.security_account_id=sa.id
       where sa.tenancy_id=?`,
      [tenancyId]
    );

    return {
      tenancyId,
      tenantName: row.tenant_name ?? "Unnamed tenant",
      lifecycleState: row.lifecycle_state,
      roomLabel: row.room_label ?? undefined,
      bedLabel: row.bed_label ?? undefined,
      outstandingMinor: row.outstanding_minor ?? 0,
      currentMonth: currentMonth.map((x:any) => ({
        obligationId: x.obligation_id,
        dueDate: x.due_date ?? undefined,
        amountMinor: x.amount_minor,
        outstandingMinor: x.outstanding_minor
      })),
      recentPayments: recent.map((x:any) => ({
        paymentId: x.payment_id,
        amountMinor: x.amount_minor,
        method: x.payment_method ?? undefined,
        occurredAt: x.occurred_at,
        eventType: x.event_type
      })),
      security: security ? {
        agreedMinor: security.agreed_amount_minor,
        heldMinor: security.held_amount_minor
      } : null
    };
  }
}

export class CollectionQueries {
  constructor(private db: QueryDb) {}

  async currentMonth(businessId: UUID): Promise<CollectionRow[]> {
    const rows = await this.db.all<any>(
      `select c.*,tr.tenant_name
       from v_current_month_collections c
       left join v_tenant_rows tr on tr.tenancy_id=c.tenancy_id
       where c.business_id=?
       order by c.due_date asc, tr.tenant_name collate nocase`,
      [businessId]
    );

    const today = new Date().toISOString().slice(0,10);

    return rows.map((r:any) => {
      let state: CollectionRow["state"];
      if (r.outstanding_minor <= 0) state = "settled";
      else if (r.settled_minor > 0) state = "part_paid";
      else if (r.due_date && r.due_date < today) state = "overdue";
      else state = "due";

      return {
        obligationId: r.obligation_id,
        tenancyId: r.tenancy_id,
        tenantName: r.tenant_name ?? "Unnamed tenant",
        dueDate: r.due_date ?? undefined,
        amountMinor: r.amount_minor,
        outstandingMinor: r.outstanding_minor,
        settledMinor: r.settled_minor,
        state
      };
    });
  }
}
