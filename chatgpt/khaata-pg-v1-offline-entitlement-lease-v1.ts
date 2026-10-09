/**
 * Khaata PG V1 — Offline Entitlement Lease + Drain Provenance v1
 * STATUS: PROPOSED MOBILE IMPLEMENTATION CONTRACT.
 *
 * Key rule:
 *   Device wall clock is NOT used to extend paid access.
 *   Effective server-relative time is derived from the last verified server time
 *   plus monotonic elapsed time while continuity is trustworthy.
 */

export type UUID = string;
export type ISODateTime = string;

export interface LeaseSnapshot {
  leaseId: UUID;
  deviceId: UUID;
  verifiedServerTimeMs: number;
  graceExpiresAtMs: number;
  effectiveEntitlements: string[];
  configVersion?: string;
  monotonicAtVerificationMs: number;
  bootSessionId: string;
}

export interface MonotonicClock {
  nowMs(): number;            // elapsed/monotonic clock, not wall clock
  bootSessionId(): string;    // changes when monotonic continuity is lost
}

export interface SecureStore {
  getLease(): Promise<LeaseSnapshot | null>;
  setLease(lease: LeaseSnapshot): Promise<void>;
}

export interface OutboxDb {
  nextLocalSequence(leaseId:UUID): Promise<number>;
  getPreviousOperationHash(leaseId:UUID): Promise<string | null>;
}

export interface Hashing {
  sha256Canonical(value: unknown): Promise<string>;
}

export class EntitlementLeaseError extends Error {
  constructor(public code:string,message:string){super(message);}
}

export class OfflineEntitlementLease {
  constructor(
    private monotonic:MonotonicClock,
    private store:SecureStore
  ){}

  async effectiveServerTimeMs():Promise<number>{
    const lease=await this.store.getLease();
    if(!lease) throw new EntitlementLeaseError("NO_VERIFIED_LEASE","No verified entitlement lease");

    if(this.monotonic.bootSessionId()!==lease.bootSessionId){
      throw new EntitlementLeaseError(
        "MONOTONIC_CONTINUITY_LOST",
        "Cannot safely extend server-relative time after monotonic continuity was lost"
      );
    }

    const elapsed=this.monotonic.nowMs()-lease.monotonicAtVerificationMs;
    if(elapsed<0){
      throw new EntitlementLeaseError("MONOTONIC_ROLLBACK","Monotonic clock moved backward");
    }
    return lease.verifiedServerTimeMs+elapsed;
  }

  async canUseOffline(entitlementKey:string):Promise<{
    allowed:boolean;
    reason:"entitled"|"not_entitled"|"grace_expired"|"continuity_lost";
  }>{
    const lease=await this.store.getLease();
    if(!lease || !lease.effectiveEntitlements.includes(entitlementKey)){
      return {allowed:false,reason:"not_entitled"};
    }

    try{
      const effectiveNow=await this.effectiveServerTimeMs();
      if(effectiveNow>lease.graceExpiresAtMs){
        return {allowed:false,reason:"grace_expired"};
      }
      return {allowed:true,reason:"entitled"};
    }catch(e){
      if(e instanceof EntitlementLeaseError &&
         (e.code==="MONOTONIC_CONTINUITY_LOST" || e.code==="MONOTONIC_ROLLBACK")){
        return {allowed:false,reason:"continuity_lost"};
      }
      throw e;
    }
  }
}

export interface DrainProvenance {
  leaseId: UUID;
  requiredEntitlement: string;
  localSequence: number;
  previousOperationHash: string | null;
  operationHash: string;
  effectiveServerTimeAtCreation: ISODateTime;
  clientCreatedAt?: ISODateTime; // informational only, never authoritative for grace
}

export class DrainProvenanceWriter {
  constructor(
    private lease:OfflineEntitlementLease,
    private store:SecureStore,
    private outbox:OutboxDb,
    private hashing:Hashing
  ){}

  async stamp(
    operationCore:{
      operationId:UUID;
      businessId:UUID;
      aggregateType:string;
      aggregateId:UUID;
      operationType:string;
      payload:unknown;
    },
    requiredEntitlement:string,
    clientCreatedAt?:ISODateTime
  ):Promise<DrainProvenance>{
    const snap=await this.store.getLease();
    if(!snap) throw new EntitlementLeaseError("NO_VERIFIED_LEASE","No entitlement lease");

    const allowed=await this.lease.canUseOffline(requiredEntitlement);
    if(!allowed.allowed){
      throw new EntitlementLeaseError(
        `OFFLINE_${allowed.reason.toUpperCase()}`,
        `Cannot create new ${requiredEntitlement} operation offline`
      );
    }

    const effectiveMs=await this.lease.effectiveServerTimeMs();
    const seq=await this.outbox.nextLocalSequence(snap.leaseId);
    const prev=await this.outbox.getPreviousOperationHash(snap.leaseId);

    const canonical={
      ...operationCore,
      leaseId:snap.leaseId,
      requiredEntitlement,
      localSequence:seq,
      previousOperationHash:prev,
      effectiveServerTimeAtCreation:new Date(effectiveMs).toISOString()
    };

    const hash=await this.hashing.sha256Canonical(canonical);

    return {
      leaseId:snap.leaseId,
      requiredEntitlement,
      localSequence:seq,
      previousOperationHash:prev,
      operationHash:hash,
      effectiveServerTimeAtCreation:canonical.effectiveServerTimeAtCreation,
      clientCreatedAt
    };
  }
}

/**
 * Sync behavior after entitlement loss:
 *
 * if current server entitlement still includes cloud_sync:
 *   normal sync
 *
 * else:
 *   for each existing outbox item carrying valid lease provenance:
 *     call validate_sync_operation_lease(...)
 *     if accepted_drain:
 *       dispatch to the same typed domain RPC
 *       DO NOT enable creation of any new cloud_sync-gated operation
 *
 * When the outbox becomes empty:
 *   exit drain-only mode
 *
 * IMPORTANT:
 * already-created local business truth remains local regardless of whether drain
 * is currently possible. The queue must not be deleted merely because entitlement
 * has expired.
 */
