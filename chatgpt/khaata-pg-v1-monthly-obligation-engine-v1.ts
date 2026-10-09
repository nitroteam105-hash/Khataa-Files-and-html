/**
 * Khaata PG / Hostel V1 — Monthly Obligation Engine v1
 * STATUS: PROPOSED IMPLEMENTATION.
 *
 * Product rules preserved:
 * - active rent agreement creates monthly obligations
 * - calendar-month billing
 * - prepaid/postpaid changes due timing
 * - due-day changes are prospective
 * - rent terms are effective-dated
 * - one deterministic obligation per tenancy/month
 * - old dues remain distinct
 * - no automatic proration is invented
 *
 * IMPORTANT:
 * Mid-month proration is not defined in the frozen PG V1 sources.
 * This engine therefore uses the full agreed monthly amount for an eligible
 * calendar period and does not silently invent prorated rent.
 */

export type UUID = string;
export type ISODate = string;
export type ISODateTime = string;
export type Minor = number;

export interface DbTx {
  run(sql:string, params?:unknown[]):Promise<void>;
  get<T>(sql:string, params?:unknown[]):Promise<T|undefined>;
  all<T>(sql:string, params?:unknown[]):Promise<T[]>;
}
export interface Db { transaction<T>(fn:(tx:DbTx)=>Promise<T>):Promise<T>; }
export interface Ids { next():UUID; }
export interface Clock { now():ISODateTime; }

export interface DomainEvents {
  append(tx:DbTx,event:{
    id:UUID;
    businessId:UUID;
    entityType:string;
    entityId:UUID;
    eventType:string;
    occurredAt:ISODateTime;
    recordedAt:ISODateTime;
    recordedByUserId:UUID;
    deviceId:UUID;
    payload:unknown;
  }):Promise<void>;
}

export interface SyncQueue {
  enqueue(tx:DbTx,input:{
    businessId:UUID;
    entityType:string;
    entityId:UUID;
    operation:"insert"|"update"|"append_event"|"retire";
    payload:unknown;
    dependencyIds?:UUID[];
  }):Promise<void>;
}

export interface CommandContext {
  businessId:UUID;
  actorUserId:UUID;
  deviceId:UUID;
}

type TenancyBillingRow = {
  tenancy_id:UUID;
  lifecycle_state:string;
  joined_at?:ISODateTime|null;
  ended_at?:ISODateTime|null;
  planned_join_date?:ISODate|null;
};

type RentTerm = {
  id:UUID;
  tenancy_id:UUID;
  amount_minor:Minor;
  billing_timing:"prepaid"|"postpaid";
  due_day:number;
  grace_days:number;
  valid_from:ISODate;
  valid_to?:ISODate|null;
};

export type ObligationGenerationResult = {
  created:number;
  alreadyPresent:number;
  skippedNoEffectiveTerm:number;
  skippedOutsideTenancy:number;
};

function parseDate(d:ISODate):Date {
  return new Date(`${d}T00:00:00Z`);
}
function isoDate(y:number,m:number,d:number):ISODate {
  return `${y.toString().padStart(4,"0")}-${m.toString().padStart(2,"0")}-${d.toString().padStart(2,"0")}`;
}
function lastDay(y:number,m:number):number {
  return new Date(Date.UTC(y,m,0)).getUTCDate();
}
function monthStart(d:ISODate):ISODate {
  const x=parseDate(d);
  return isoDate(x.getUTCFullYear(),x.getUTCMonth()+1,1);
}
function monthEnd(periodStart:ISODate):ISODate {
  const x=parseDate(periodStart);
  const y=x.getUTCFullYear(), m=x.getUTCMonth()+1;
  return isoDate(y,m,lastDay(y,m));
}
function nextMonth(periodStart:ISODate):ISODate {
  const x=parseDate(periodStart);
  const n=new Date(Date.UTC(x.getUTCFullYear(),x.getUTCMonth()+1,1));
  return isoDate(n.getUTCFullYear(),n.getUTCMonth()+1,1);
}
function maxDate(a:ISODate,b:ISODate):ISODate {
  return a>=b?a:b;
}
function minDate(a:ISODate,b:ISODate):ISODate {
  return a<=b?a:b;
}
function dateOnly(ts?:ISODateTime|null):ISODate|undefined {
  return ts ? ts.slice(0,10) : undefined;
}
function clampDueDay(periodStart:ISODate,dueDay:number):ISODate {
  const x=parseDate(periodStart);
  const y=x.getUTCFullYear(), m=x.getUTCMonth()+1;
  return isoDate(y,m,Math.min(Math.max(dueDay,1),lastDay(y,m)));
}
function addMonths(periodStart:ISODate,count:number):ISODate {
  const x=parseDate(periodStart);
  const n=new Date(Date.UTC(x.getUTCFullYear(),x.getUTCMonth()+count,1));
  return isoDate(n.getUTCFullYear(),n.getUTCMonth()+1,1);
}

function termEffectiveForPeriod(terms:RentTerm[], periodStart:ISODate, periodEnd:ISODate):RentTerm|undefined {
  // Terms are effective-dated. We deliberately require the term to overlap the
  // period and choose the one with the latest valid_from not after period end.
  // This guarantees one term per tenancy/month.
  return terms
    .filter(t => t.valid_from<=periodEnd && (!t.valid_to || t.valid_to>=periodStart))
    .sort((a,b)=> b.valid_from.localeCompare(a.valid_from))[0];
}

function dueDateFor(term:RentTerm,periodStart:ISODate):ISODate {
  // Prepaid: due inside the billed month.
  // Postpaid: due in the next calendar month.
  const duePeriod = term.billing_timing==="prepaid"
    ? periodStart
    : addMonths(periodStart,1);
  return clampDueDay(duePeriod,term.due_day);
}

export class MonthlyObligationEngine {
  constructor(private deps:{
    db:Db;
    ids:Ids;
    clock:Clock;
    events:DomainEvents;
    sync:SyncQueue;
  }){}

  async ensureThrough(
    ctx:CommandContext,
    throughPeriod:ISODate
  ):Promise<ObligationGenerationResult>{
    return this.deps.db.transaction(async tx=>{
      const tenancies = await tx.all<TenancyBillingRow>(
        `select id as tenancy_id,lifecycle_state,joined_at,ended_at,planned_join_date
         from tenancies
         where business_id=?
           and lifecycle_state in ('active','planned_move_out','moved_out')`,
        [ctx.businessId]
      );

      let created=0;
      let alreadyPresent=0;
      let skippedNoEffectiveTerm=0;
      let skippedOutsideTenancy=0;

      for(const tenancy of tenancies){
        const terms = await tx.all<RentTerm>(
          `select id,tenancy_id,amount_minor,billing_timing,due_day,grace_days,
                  valid_from,valid_to
           from rent_terms
           where tenancy_id=?
           order by valid_from asc`,
          [tenancy.tenancy_id]
        );
        if(!terms.length) continue;

        const joined = dateOnly(tenancy.joined_at) ?? tenancy.planned_join_date;
        if(!joined) continue;

        const firstEligibleMonth = monthStart(joined);
        const lastEligibleDate = dateOnly(tenancy.ended_at) ?? throughPeriod;
        const lastEligibleMonth = monthStart(minDate(lastEligibleDate,throughPeriod));

        let periodStart=firstEligibleMonth;

        while(periodStart<=lastEligibleMonth){
          const periodEnd=monthEnd(periodStart);

          const tenancyStart=joined;
          const tenancyEnd=dateOnly(tenancy.ended_at);

          const overlapsTenancy =
            periodEnd>=tenancyStart &&
            (!tenancyEnd || periodStart<=tenancyEnd);

          if(!overlapsTenancy){
            skippedOutsideTenancy++;
            periodStart=nextMonth(periodStart);
            continue;
          }

          const term=termEffectiveForPeriod(terms,periodStart,periodEnd);
          if(!term){
            skippedNoEffectiveTerm++;
            periodStart=nextMonth(periodStart);
            continue;
          }

          // Explicitly avoid inventing automatic proration. If a tenancy/term
          // begins mid-month, the current frozen model does not define a fraction.
          const deterministicKey=`rent:${tenancy.tenancy_id}:${periodStart}`;

          const exists=await tx.get<{id:UUID}>(
            `select id from obligations
             where business_id=? and deterministic_key=?`,
            [ctx.businessId,deterministicKey]
          );

          if(exists){
            alreadyPresent++;
            periodStart=nextMonth(periodStart);
            continue;
          }

          const obligationId=this.deps.ids.next();
          const createdAt=this.deps.clock.now();
          const dueDate=dueDateFor(term,periodStart);

          await tx.run(
            `insert into obligations(
              id,business_id,tenancy_id,obligation_type,
              period_start,period_end,due_date,amount_minor,
              deterministic_key,created_at
            ) values (?,?,?,'rent',?,?,?,?,?,?)`,
            [
              obligationId,ctx.businessId,tenancy.tenancy_id,
              periodStart,periodEnd,dueDate,term.amount_minor,
              deterministicKey,createdAt
            ]
          );

          const eventId=this.deps.ids.next();
          await this.deps.events.append(tx,{
            id:eventId,
            businessId:ctx.businessId,
            entityType:"obligation",
            entityId:obligationId,
            eventType:"monthly_rent_obligation_created",
            occurredAt:`${periodStart}T00:00:00Z`,
            recordedAt:createdAt,
            recordedByUserId:ctx.actorUserId,
            deviceId:ctx.deviceId,
            payload:{
              tenancyId:tenancy.tenancy_id,
              rentTermId:term.id,
              periodStart,
              periodEnd,
              dueDate,
              amountMinor:term.amount_minor,
              billingTiming:term.billing_timing,
              graceDays:term.grace_days,
              deterministicKey,
              prorationApplied:false
            }
          });

          await this.deps.sync.enqueue(tx,{
            businessId:ctx.businessId,
            entityType:"obligation",
            entityId:obligationId,
            operation:"insert",
            payload:{id:obligationId},
            dependencyIds:[tenancy.tenancy_id,term.id]
          });

          created++;
          periodStart=nextMonth(periodStart);
        }
      }

      return {created,alreadyPresent,skippedNoEffectiveTerm,skippedOutsideTenancy};
    });
  }
}

/**
 * Prospective rent change rule:
 *
 * A rent change creates a new rent_term with a later valid_from.
 * Historical obligations remain unchanged.
 *
 * If two rent terms overlap the same calendar period, this engine picks the one
 * with the latest valid_from for that period. That prevents duplicate monthly
 * obligations, but a contradictory overlapping term should still be surfaced
 * elsewhere as a semantic conflict during sync/review.
 */
