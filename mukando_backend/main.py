"""
MukandoChain backend.

An append-only, hash-chained ledger for a rotating savings group (mukando/round).
Every record stores the hash of the record before it, so changing any old record
breaks the chain and is detected by /api/verify.

This is a demo group with fake members. Real deployments need logins, roles
and a database (see README).
"""
import hashlib
import json
import time

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

GROUP = {"name": "Unity Mukando Circle", "contribution": 20, "currency": "USD"}
NAMES = ["Tendai", "Rudo", "Farai", "Chipo", "Tatenda", "Nyasha", "Kudzai", "Tariro"]
MEMBERS = [{"id": f"m{i + 1}", "name": n} for i, n in enumerate(NAMES)]
GENESIS = "0" * 64

LEDGER = []


# ---------- ledger core ----------

def block_hash(b):
    payload = json.dumps(
        {"index": b["index"], "ts": b["ts"], "type": b["type"],
         "data": b["data"], "prev": b["prev"]},
        sort_keys=True, separators=(",", ":"),
    )
    return hashlib.sha256(payload.encode()).hexdigest()


def add_block(kind, data, ts=None):
    prev = LEDGER[-1]["hash"] if LEDGER else GENESIS
    b = {"index": len(LEDGER), "ts": ts or time.time(), "type": kind,
         "data": data, "prev": prev}
    b["hash"] = block_hash(b)
    LEDGER.append(b)
    return b


def verify():
    prev = GENESIS
    for b in LEDGER:
        if b["prev"] != prev or block_hash(b) != b["hash"]:
            return {"valid": False, "checked": len(LEDGER),
                    "bad_index": b["index"], "head": LEDGER[-1]["hash"]}
        prev = b["hash"]
    return {"valid": True, "checked": len(LEDGER), "bad_index": None,
            "head": LEDGER[-1]["hash"] if LEDGER else GENESIS}


# ---------- state is always replayed from the ledger ----------

def replay():
    cycle = 1
    paid = {}
    received = {}
    totals = {m["id"]: 0 for m in MEMBERS}
    for b in LEDGER:
        d = b["data"]
        if b["type"] == "CONTRIBUTION":
            paid[d["member_id"]] = d["amount"]
            totals[d["member_id"]] = totals.get(d["member_id"], 0) + d["amount"]
        elif b["type"] == "PAYOUT":
            received[d["member_id"]] = d["cycle"]
            cycle += 1
            paid = {}
    return cycle, paid, received, totals


def member_by_id(mid):
    for m in MEMBERS:
        if m["id"] == mid:
            return m
    raise HTTPException(404, "Member not found")


def record_contribution(mid, ts=None):
    cycle, paid, _, _ = replay()
    n = len(MEMBERS)
    if cycle > n:
        raise HTTPException(409, "Round complete. Start a new round.")
    m = member_by_id(mid)
    if mid in paid:
        raise HTTPException(409, f"{m['name']} has already paid this cycle")
    return add_block("CONTRIBUTION", {
        "member_id": mid, "member_name": m["name"],
        "amount": GROUP["contribution"], "cycle": cycle,
        "recorded_by": "Treasurer",
    }, ts)


def record_payout(ts=None):
    cycle, paid, _, _ = replay()
    n = len(MEMBERS)
    if cycle > n:
        raise HTTPException(409, "Round complete.")
    if len(paid) < n:
        raise HTTPException(409, "Not everyone has paid yet")
    recipient = MEMBERS[(cycle - 1) % n]
    return add_block("PAYOUT", {
        "member_id": recipient["id"], "member_name": recipient["name"],
        "amount": sum(paid.values()), "cycle": cycle,
    }, ts)


def seed():
    LEDGER.clear()
    day = 86400
    start = time.time() - 75 * day
    add_block("GROUP_CREATED", {
        "name": GROUP["name"], "contribution": GROUP["contribution"],
        "members": NAMES,
    }, start)
    for cycle in (1, 2):
        base = start + ((cycle - 1) * 25 + 5) * day
        for k, m in enumerate(MEMBERS):
            record_contribution(m["id"], base + k * 3600 * 5)
        record_payout(base + 10 * day)
    base = start + 55 * day
    for k, mid in enumerate(["m1", "m2", "m3", "m5", "m7"]):
        record_contribution(mid, base + k * day)


# ---------- API ----------

app = FastAPI(title="MukandoChain API")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)
seed()


@app.get("/api/state")
def state():
    cycle, paid, received, totals = replay()
    n = len(MEMBERS)
    complete = cycle > n
    recipient = None if complete else MEMBERS[(cycle - 1) % n]
    members = [{
        "id": m["id"], "name": m["name"], "paid": m["id"] in paid,
        "received_cycle": received.get(m["id"]),
        "total_paid": totals.get(m["id"], 0),
    } for m in MEMBERS]
    return {
        "group": {**GROUP, "members": n},
        "cycle": min(cycle, n), "round_complete": complete,
        "pot": sum(paid.values()), "target": GROUP["contribution"] * n,
        "recipient": recipient,
        "can_payout": (not complete) and len(paid) == n,
        "members": members,
        "integrity": verify(),
        "ledger": list(reversed(LEDGER)),
    }


@app.get("/api/verify")
def verify_endpoint():
    return verify()


@app.post("/api/members/{member_id}/contribute")
def contribute(member_id: str):
    return record_contribution(member_id)


@app.post("/api/payout")
def payout():
    return record_payout()


@app.post("/api/demo/fill")
def demo_fill():
    cycle, paid, _, _ = replay()
    if cycle > len(MEMBERS):
        raise HTTPException(409, "Round complete. Reset the demo.")
    for m in MEMBERS:
        if m["id"] not in paid:
            record_contribution(m["id"])
    return {"ok": True}


@app.post("/api/demo/tamper")
def demo_tamper():
    """Simulates a dishonest edit: changes a recorded amount WITHOUT redoing the hashes."""
    for b in reversed(LEDGER):
        if b["type"] == "CONTRIBUTION":
            b["data"]["amount"] = 2
            return {"tampered_block": b["index"]}
    raise HTTPException(409, "Nothing to tamper with")


@app.post("/api/demo/reset")
def demo_reset():
    seed()
    return {"ok": True}
