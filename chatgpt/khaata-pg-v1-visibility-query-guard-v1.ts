/**
 * Khaata PG V1 — Visibility-Aware Query Guard v1
 * STATUS: PROPOSED IMPLEMENTATION CONTRACT.
 *
 * Purpose:
 *   Apply read visibility independently from write/action permission.
 *
 * Product invariants:
 * - Visibility is separate from action permission.
 * - A user may be allowed to perform an action without seeing all business data.
 * - Disabled staff cannot gain new operational access, but historical attribution remains.
 * - Owner-only operation is valid.
 * - Offline-cached data and permission to act are separate concerns.
 */

export type UUID = string;
export type Minor = number;

export interface QueryDb {
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
  all<T>(sql:string, params?:unknown[]):Promise<T[]>;
}

export interface ViewerContext {
  businessId: UUID;
  userId: UUID;
}

export interface VisibilitySet {
  tenantRecords: boolean;
  tenantBalances: boolean;
  tenantSensitiveIdentity: boolean;
  expenses: boolean;
  rooms: boolean;
  staffCashCustody: boolean;
  staffAccess: boolean;
}

export interface ViewerAccess {
  isOwner: boolean;
  membershipId?: UUID;
  visibility: VisibilitySet;
}

export class VisibilityDenied extends Error {
  constructor(public code:string, message:string){ super(message); }
}

const FULL_VISIBILITY: VisibilitySet = {
  tenantRecords: true,
  tenantBalances: true,
  tenantSensitiveIdentity: true,
  expenses: true,
  rooms: true,
  staffCashCustody: true,
  staffAccess: true
};

const HIDDEN_VISIBILITY: VisibilitySet = {
  tenantRecords: false,
  tenantBalances: false,
  tenantSensitiveIdentity: false,
  expenses: false,
  rooms: false,
  staffCashCustody: false,
  staffAccess: false
};

export class VisibilityResolver {
  constructor(private db: QueryDb) {}

  async resolve(ctx: ViewerContext): Promise<ViewerAccess> {
    const business = await this.db.get<{owner_user_id:UUID}>(
      `select owner_user_id from businesses where id=?`,
      [ctx.businessId]
    );
    if(!business) throw new VisibilityDenied("BUSINESS_NOT_FOUND","Business not found");

    if(business.owner_user_id===ctx.userId){
      return { isOwner:true, visibility:{...FULL_VISIBILITY} };
    }

    const membership = await this.db.get<{id:UUID;membership_state:string}>(
      `select id,membership_state from staff_memberships
       where business_id=? and user_id=?`,
      [ctx.businessId,ctx.userId]
    );

    if(!membership || membership.membership_state!=="active"){
      throw new VisibilityDenied("NO_ACTIVE_ACCESS","No active staff access");
    }

    const rows = await this.db.all<{visibility_key:string;is_visible:number}>(
      `select visibility_key,is_visible
       from v_effective_staff_visibility
       where membership_id=?`,
      [membership.id]
    );

    const result = {...HIDDEN_VISIBILITY};
    for(const row of rows){
      const visible = row.is_visible===1;
      switch(row.visibility_key){
        case "tenant_records": result.tenantRecords=visible; break;
        case "tenant_balances": result.tenantBalances=visible; break;
        case "tenant_sensitive_identity": result.tenantSensitiveIdentity=visible; break;
        case "expenses": result.expenses=visible; break;
        case "rooms": result.rooms=visible; break;
        case "staff_cash_custody": result.staffCashCustody=visible; break;
        case "staff_access": result.staffAccess=visible; break;
      }
    }

    return { isOwner:false, membershipId:membership.id, visibility:result };
  }

  require(vis: VisibilitySet, key:keyof VisibilitySet): void {
    if(!vis[key]){
      throw new VisibilityDenied("VISIBILITY_BLOCKED",`${String(key)} is hidden for this viewer`);
    }
  }
}

/* -------------------------------------------------------------------------- */
/* REDACTION HELPERS                                                           */
/* -------------------------------------------------------------------------- */

export interface TenantRowRaw {
  tenancy_id: UUID;
  tenant_name?: string;
  lifecycle_state: string;
  room_label?: string;
  bed_label?: string;
  outstanding_minor?: number;
  phone?: string;
}

export interface TenantRowVisible {
  tenancyId: UUID;
  tenantName: string;
  lifecycleState: string;
  roomLabel?: string;
  bedLabel?: string;
  outstandingMinor?: Minor;
  phone?: string;
}

export function redactTenantRow(
  raw: TenantRowRaw,
  vis: VisibilitySet
): TenantRowVisible {
  if(!vis.tenantRecords){
    throw new VisibilityDenied("TENANT_RECORDS_HIDDEN","Tenant records are hidden");
  }

  return {
    tenancyId: raw.tenancy_id,
    tenantName: raw.tenant_name ?? "Unnamed tenant",
    lifecycleState: raw.lifecycle_state,
    roomLabel: vis.rooms ? raw.room_label : undefined,
    bedLabel: vis.rooms ? raw.bed_label : undefined,
    outstandingMinor: vis.tenantBalances ? (raw.outstanding_minor ?? 0) : undefined,
    phone: vis.tenantSensitiveIdentity ? raw.phone : undefined
  };
}

/* -------------------------------------------------------------------------- */
/* VISIBILITY-AWARE TENANT QUERIES                                             */
/* -------------------------------------------------------------------------- */

export class TenantVisibleQueries {
  constructor(
    private db:QueryDb,
    private resolver:VisibilityResolver
  ){}

  async list(ctx:ViewerContext):Promise<TenantRowVisible[]>{
    const access = await this.resolver.resolve(ctx);
    this.resolver.require(access.visibility,"tenantRecords");

    const rows = await this.db.all<TenantRowRaw>(
      `select tr.tenancy_id,tr.tenant_name,tr.lifecycle_state,
              tr.room_label,tr.bed_label,tr.outstanding_minor,
              p.phone
       from v_tenant_rows tr
       left join tenancy_role_assignments tra
         on tra.tenancy_id=tr.tenancy_id
        and tra.role_type='occupant'
        and tra.valid_to is null
       left join parties p on p.id=tra.party_id
       where tr.business_id=?
       order by tr.tenant_name collate nocase`,
      [ctx.businessId]
    );

    return rows.map(r=>redactTenantRow(r,access.visibility));
  }

  async detail(ctx:ViewerContext,tenancyId:UUID):Promise<TenantRowVisible|null>{
    const access = await this.resolver.resolve(ctx);
    this.resolver.require(access.visibility,"tenantRecords");

    const row = await this.db.get<TenantRowRaw>(
      `select tr.tenancy_id,tr.tenant_name,tr.lifecycle_state,
              tr.room_label,tr.bed_label,tr.outstanding_minor,
              p.phone
       from v_tenant_rows tr
       left join tenancy_role_assignments tra
         on tra.tenancy_id=tr.tenancy_id
        and tra.role_type='occupant'
        and tra.valid_to is null
       left join parties p on p.id=tra.party_id
       where tr.business_id=? and tr.tenancy_id=?`,
      [ctx.businessId,tenancyId]
    );
    return row ? redactTenantRow(row,access.visibility) : null;
  }
}

/* -------------------------------------------------------------------------- */
/* COLLECTION QUERIES                                                          */
/* -------------------------------------------------------------------------- */

export class CollectionVisibleQueries {
  constructor(
    private db:QueryDb,
    private resolver:VisibilityResolver
  ){}

  async currentMonth(ctx:ViewerContext):Promise<Array<{
    obligationId:UUID;
    tenancyId:UUID;
    tenantName:string;
    dueDate?:string;
    amountMinor?:Minor;
    outstandingMinor?:Minor;
    settledMinor?:Minor;
  }>>{
    const access = await this.resolver.resolve(ctx);

    // Tenant records must be visible to identify rows.
    this.resolver.require(access.visibility,"tenantRecords");

    const rows = await this.db.all<any>(
      `select c.*,tr.tenant_name
       from v_current_month_collections c
       left join v_tenant_rows tr on tr.tenancy_id=c.tenancy_id
       where c.business_id=?
       order by c.due_date asc`,
      [ctx.businessId]
    );

    return rows.map((r:any)=>({
      obligationId:r.obligation_id,
      tenancyId:r.tenancy_id,
      tenantName:r.tenant_name ?? "Unnamed tenant",
      dueDate:r.due_date ?? undefined,
      amountMinor:access.visibility.tenantBalances ? r.amount_minor : undefined,
      outstandingMinor:access.visibility.tenantBalances ? r.outstanding_minor : undefined,
      settledMinor:access.visibility.tenantBalances ? r.settled_minor : undefined
    }));
  }
}

/* -------------------------------------------------------------------------- */
/* EXPENSE QUERIES                                                             */
/* -------------------------------------------------------------------------- */

export class ExpenseVisibleQueries {
  constructor(
    private db:QueryDb,
    private resolver:VisibilityResolver
  ){}

  async list(ctx:ViewerContext):Promise<any[]>{
    const access = await this.resolver.resolve(ctx);
    this.resolver.require(access.visibility,"expenses");

    return this.db.all(
      `select id,amount_minor,category,paid_by_type,expense_date,vendor,reimbursement_state
       from expenses where business_id=?
       order by expense_date desc,created_at desc`,
      [ctx.businessId]
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STAFF CASH CUSTODY                                                          */
/* -------------------------------------------------------------------------- */

export class CashCustodyVisibleQueries {
  constructor(
    private db:QueryDb,
    private resolver:VisibilityResolver
  ){}

  async list(ctx:ViewerContext):Promise<any[]>{
    const access = await this.resolver.resolve(ctx);
    this.resolver.require(access.visibility,"staffCashCustody");

    return this.db.all(
      `select id,event_type,from_party_id,to_party_id,amount_minor,occurred_at,reason
       from cash_custody_events
       where business_id=?
       order by occurred_at desc`,
      [ctx.businessId]
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STAFF ACCESS                                                                */
/* -------------------------------------------------------------------------- */

export class StaffAccessVisibleQueries {
  constructor(
    private db:QueryDb,
    private resolver:VisibilityResolver
  ){}

  async members(ctx:ViewerContext):Promise<any[]>{
    const access = await this.resolver.resolve(ctx);
    this.resolver.require(access.visibility,"staffAccess");

    return this.db.all(
      `select id,user_id,role_name,membership_state,created_at,disabled_at
       from staff_memberships
       where business_id=?
       order by membership_state,created_at`,
      [ctx.businessId]
    );
  }
}

/**
 * IMPORTANT OFFLINE NOTE
 *
 * This layer controls what the application presents from cached SQLite data.
 * It does not claim that previously cached bytes are cryptographically erased
 * when a role changes while the device is offline.
 *
 * Production hardening may additionally require:
 * - database/file encryption at rest,
 * - session lock / re-auth,
 * - secure cache purging for sensitive documents,
 * - remote-wipe/revocation policy,
 * - OS-level storage protections.
 *
 * Those are implementation/security decisions, not substitutes for visibility checks.
 */
