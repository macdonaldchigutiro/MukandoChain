# MukandoChain - backend

A hash-chained ledger for rotating savings groups (mukando / round).
Demo group: 8 members, $20 each per cycle, payout rotates every cycle.

## Run (Windows)
    cd mukando_backend
    python -m venv venv
    venv\Scripts\activate
    pip install -r requirements.txt
    python -m uvicorn main:app --reload --host 0.0.0.0 --port 8001

(Port 8001 so it can run next to your other backends.)

Check it: http://127.0.0.1:8001/api/state
Docs and test buttons: http://127.0.0.1:8001/docs

## How the "blockchain" works
Every record (block) stores the SHA-256 hash of the block before it.
Change any old record and its hash no longer matches, which breaks the chain.
GET /api/verify recomputes everything and tells you the first bad block.
All balances are rebuilt from the ledger, so there is no separate balance
that someone could quietly edit.

Demo: POST /api/demo/tamper changes a $20 payment to $2 without fixing the
hashes. The app then shows TAMPERING DETECTED. POST /api/demo/reset restores it.

## Honest limits of this demo
- This is a private hash-chained ledger on one server. To make it truly
  tamper-resistant: have members' phones keep copies, and publish the latest
  hash (the "head") to a public blockchain once a day.
- There are no logins yet. A real version needs member accounts, a treasurer
  role, and ideally two people to approve each payout.
- State lives in memory and resets when the server restarts. Add a database
  (SQLite or PostgreSQL) next.
- It records money, it does not move money. Connecting to EcoCash or
  OneMoney needs their merchant APIs and approval.
- Check local rules for savings groups and data protection before real use.
