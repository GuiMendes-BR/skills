# System Architecture: Company CRM

## Overview

**System Name**: Company CRM  
**Purpose**: Multi-team customer relationship management system for deal pipeline visibility, customer relationship intelligence, and customer health tracking  
**Primary Use Case**: Sales pipeline management + customer lifecycle tracking  
**Critical Workflow Driver**: Sales team (deal progression), with supporting workflows from Support (customer health) and Finance (revenue forecasting)  
**Scale**: ~500 Accounts, ~1000 Deals, 20 concurrent users

---

## Business Context

### Problem Being Solved

Currently, customer data is scattered across Slack, email, spreadsheets, and personal notes. This creates:
- **No pipeline visibility**: Sales reps don't know deal status across the team
- **Fragmented customer history**: Support can't see customer context when handling tickets
- **Manual reporting burden**: Finance spends 4 hours weekly compiling reports
- **Duplicated contacts**: Sales reps add the same contact multiple times
- **Lost institutional knowledge**: Customer insights stuck in Slack threads

### Solution

A unified Notion CRM that serves as the single source of truth for:
1. **Sales Pipeline**: Deal progression from Prospect → Won/Lost
2. **Customer Relationships**: All contacts and interaction history per account
3. **Customer Health**: Activity frequency, support ticket volume, sentiment trends
4. **Revenue Tracking**: MRR/ARR visibility and forecasting
5. **Team Collaboration**: Slack notifications for key events, shared account ownership

---

## Core Entities & Data Model

### 1. Accounts (Companies)

**Icon**: 🏢 | **Color**: Blue  
**Purpose**: Single record per company we do business with

**Properties**:

| Property | Type | Required | Description |
|---|---|---|---|
| name | Title | ✓ | Company legal name |
| status | Select | ✓ | Prospect / Active / Churned |
| industry | Select | | SaaS / Healthcare / Finance / Manufacturing |
| mrr | Number | | Monthly recurring revenue |
| last_activity_date | Date | | Date of last customer interaction (auto-updated by Claude) |
| health_score | Number | | 1-10 customer health (recalculated daily) |
| contact_count | Rollup | | Number of contacts (auto-count) |
| deal_count | Rollup | | Number of active deals (auto-count) |
| total_mrr | Rollup | | Sum of all deal MRR (auto-sum) |
| contacts | Relation | | All people at this account |
| deals | Relation | | All deals with this account |
| tickets | Relation | | All support tickets for this account |

**Key Workflows**:
- New account created by sales rep with status=Prospect
- Once qualified and first deal moves to Proposal, status moves to Active
- If all deals are lost and no activity for 60 days, status → Churned
- Stripe sync auto-creates/updates Accounts on subscription events

**Validation Rules**:
- Name is required
- Status cannot be blank
- Soft delete only (never hard delete)

**Views**:
- **Active Accounts** (Table): Shows only Active status, sortable by health_score
- **By Industry** (Table): Grouped by industry for market analysis
- **At-Risk Accounts** (Table): health_score < 5 and status = Active (early warning system)

---

### 2. Contacts (People)

**Icon**: 👤 | **Color**: Purple  
**Purpose**: Individual people at accounts, tracked for relationship intelligence

**Properties**:

| Property | Type | Required | Description |
|---|---|---|---|
| name | Title | ✓ | Full name |
| email | Email | ✓ | Primary work email (required for enrichment) |
| phone | Phone | | Primary work phone (often enriched by Claude) |
| account | Relation | ✓ | Parent account |
| role | Select | | Decision Maker / Influencer / End User / Unknown |
| seniority | Select | | C-Level / VP / Manager / IC |
| last_contacted | Date | | Date of last interaction (auto-updated) |
| activity_count | Rollup | | Number of interactions (auto-count) |

**Key Workflows**:
- Sales rep adds contact to Account with email
- Claude enriches phone and role (with review required)
- When Activity is created with this contact, last_contacted auto-updates
- Support team uses to see customer context when ticket arrives

**Validation Rules**:
- Name and email required
- Must be linked to an account
- Email must be valid format

**Views**:
- **Decision Makers** (Table): Filtered to role="Decision Maker" only
- **By Account** (Gallery): All contacts at an account, easy contact view

**Claude Enrichment**:
- If phone is missing, Claude looks up from email domain/company and proposes
- If role is missing, Claude infers from email (C-suite, manager, etc.)
- Human review required before saving enriched data

---

### 3. Deals (Opportunities)

**Icon**: 💰 | **Color**: Green  
**Purpose**: Sales opportunities and pipeline tracking

**Properties**:

| Property | Type | Required | Description |
|---|---|---|---|
| title | Title | ✓ | Deal name/description |
| stage | Select | ✓ | Prospect / Qualified / Proposal / Negotiation / Won / Lost |
| mrr | Number | ✓ | Monthly recurring revenue |
| arr | Number | | Annual recurring revenue (12 × MRR) |
| probability | Select | | 10% / 25% / 50% / 75% / 90% |
| close_date | Date | | Expected close date |
| actual_close_date | Date | | When actually closed |
| account | Relation | ✓ | Account this deal is with |
| primary_contact | Relation | | Main contact for this deal |
| sales_rep | Select | | Rep 1 / Rep 2 / Rep 3 / Unassigned |
| notes | Rich Text | | Deal context and context |

**Key Workflows** (State Machine):

```
Prospect 
  → Qualified (rep moves after initial call/meeting)
    → Proposal (proposal created and sent)
      → Negotiation (customer reviewing terms)
        → Won (deal closed, celebrate!)
        
    → Lost (customer chose competitor or declined)
```

**Transition Rules**:
- Any rep can create a deal
- Only deal owner (sales_rep) can move deal forward
- Deals can move backward (re-open lost deal, move Negotiation → Proposal)
- When deal moves to Won, Slack notification fires to team
- When deal moves to Won, finance is notified for revenue tracking

**Validation Rules**:
- Title, stage, MRR required
- Stage cannot be blank
- MRR must be > 0
- Deals require an account
- Soft delete only

**Views**:
- **Pipeline by Stage** (Kanban): Visual pipeline, drag deals between stages
- **My Deals** (Table): Deals assigned to me that aren't Won/Lost
- **Forecast** (Table): All open deals with probability and close_date for revenue forecasting

**Claude Integration**:
- Claude can auto-update last_activity_date when activities logged
- Claude helps forecast pipeline value
- Claude alerts on stalled deals (no activity for 14+ days)

---

### 4. Activities (Interactions)

**Icon**: 📞 | **Color**: Yellow  
**Purpose**: Log every customer interaction and extract insights

**Properties**:

| Property | Type | Required | Description |
|---|---|---|---|
| title | Title | ✓ | Activity summary (e.g., "Budget discussion") |
| type | Select | ✓ | Call / Email / Meeting / Demo / Note |
| contact | Relation | ✓ | Person involved |
| account | Relation | | Account involved |
| deal | Relation | | Related deal (if applicable) |
| activity_date | Date | ✓ | When it occurred |
| duration_minutes | Number | | For calls/meetings |
| notes | Rich Text | | What was discussed (Claude enriches with insights) |
| key_outcomes | Rich Text | | Decisions made, next steps (auto-populated by Claude) |
| sentiment | Select | | Positive / Neutral / Negative |
| next_steps | Rich Text | | Follow-up actions (auto-populated by Claude) |
| created_at | Created Time | | When record was created |

**Key Workflows**:
- Sales rep creates Activity after any customer interaction
- Claude automatically:
  1. Updates contact.last_contacted to today
  2. Updates account.last_activity_date to today
  3. Extracts key_outcomes and next_steps from notes
  4. Sets sentiment based on tone
4. Recalculates account.health_score

**Validation Rules**:
- Type and contact required
- Activity_date must be in past or today
- Notes should not be empty for meetings (at least a summary)

**Views**:
- **This Week** (Table): Activities from past 7 days
- **By Contact** (Timeline): Chronological view of all interactions with one person

**Claude Enrichment**:
- Reads activity notes and extracts: key decisions, risks, next steps, stakeholder sentiment
- Appends structured insights to key_outcomes field (never overwrites original notes)
- Updates sentiment field based on language analysis

---

### 5. Support Tickets

**Icon**: 🎫 | **Color**: Red  
**Purpose**: Track customer support cases and link to accounts/deals

**Properties**:

| Property | Type | Required | Description |
|---|---|---|---|
| title | Title | ✓ | Ticket subject |
| type | Select | | Bug / Feature Request / Account Issue / Billing |
| status | Select | ✓ | Open / In Progress / Waiting on Customer / Resolved |
| priority | Select | | Critical / High / Medium / Low |
| account | Relation | ✓ | Account with issue |
| contact | Relation | | Contact who reported |
| assigned_to | Select | | Support team member |
| description | Rich Text | | Issue details |
| resolution | Rich Text | | How it was resolved |
| created_at | Created Time | | When reported |
| resolved_at | Date | | When resolved |

**Key Workflows**:
- Support receives ticket (manually created or from email forward)
- Ticket linked to Account so sales can see account history
- Critical tickets trigger Slack alert to sales rep + support
- When ticket resolved, account.health_score recalculated

**Integration with Sales**:
- Sales rep can see all tickets for an account (visibility into customer pain)
- Critical/urgent tickets surface in "At-Risk Accounts" view
- Support can see deal status (know if customer is in negotiation, helps context)

**Validation Rules**:
- Title and account required
- Status must be set
- Priority should be set for SLA tracking

**Views**:
- **Open Tickets** (Table): All non-resolved tickets, sorted by priority
- **By Account** (Table): All tickets for an account in one view

---

## Relationships & Data Flow

```
┌─────────────────────────────────────┐
│ Accounts (500 total)                │
│ - status, health_score, mrr         │
└──────────┬──────────────────────────┘
           │
           ├─────────────────────────┬──────────────────────────┐
           │                         │                          │
           ↓                         ↓                          ↓
     ┌────────────┐          ┌──────────────┐        ┌─────────────────┐
     │ Contacts   │          │ Deals        │        │ Support Tickets │
     │ (1000+)    │          │ (~1000)      │        │ (~200)          │
     └────────────┘          └──────────────┘        └─────────────────┘
           │                         │                          │
           └─────────────────────────┼──────────────────────────┘
                                     │
                                     ↓
                            ┌─────────────────┐
                            │ Activities      │
                            │ (2000+ monthly) │
                            └─────────────────┘
```

**Cardinality**:
- 1 Account → Many Contacts (1:N)
- 1 Account → Many Deals (1:N)
- 1 Account → Many Tickets (1:N)
- 1 Contact → Many Activities (1:N)
- 1 Deal → Many Activities (1:N)
- 1 Deal → 1 Account (N:1)

**Deletion Cascade** (Soft Delete Only):
- Delete Account → all Contacts, Deals, Tickets marked deleted
- Delete Contact → Activities archived but not deleted
- Delete Deal → soft-deleted (can be restored for 90 days)
- Deleted records remain in database for audit trail

---

## Workflows & State Machines

### Workflow 1: Deal Pipeline (Primary Sales Workflow)

**Trigger**: Sales rep creates Deal

**States & Transitions**:

```
1. PROSPECT (Initial state)
   ├─ Rep qualifies account → QUALIFIED
   └─ Never happens → Lost

2. QUALIFIED (Opportunity confirmed)
   ├─ Proposal created & sent → PROPOSAL
   └─ Customer not interested → Lost

3. PROPOSAL (Proposal under review)
   ├─ Customer agrees to terms → NEGOTIATION
   └─ Customer declines → Lost

4. NEGOTIATION (Final terms being negotiated)
   ├─ Contract signed → WON
   └─ Deal falls apart → Lost

5. WON (Closed successfully)
   └─ [Terminal state - can reopen if customer backs out]

6. LOST (Deal closed unsuccessfully)
   └─ [Terminal state - can reopen if customer reconsiders]
```

**Permissions**:
- Sales rep can move own deals forward
- Manager can move any rep's deal
- No backward movement without manager approval

**Notifications**:
- Deal moves to PROPOSAL: Slack to sales rep (reminder to send)
- Deal moves to WON: Slack to team + Finance
- Deal moves to LOST: Slack to rep + manager (analysis required)

**Claude Integration**:
- After 14 days in same stage, Claude sends "stalled deal" alert
- Claude forecasts probability of close based on stage duration + activity

---

### Workflow 2: Account Health Scoring

**Trigger**: Activity created OR Ticket created OR Deal status changes

**Calculation** (0-10 scale):

```
Health Score = (engagement_score + support_score + revenue_trend_score) / 3

Engagement Score:
  - Days since last_activity: 0 days = 10, 7 days = 5, 14+ days = 0

Support Score:
  - Tickets in past 30 days: 0 = 10, 1-2 = 8, 3+ = 0
  - Critical/High priority tickets: -2 each

Revenue Trend Score:
  - MRR growing: +3
  - MRR flat: +1
  - MRR declining: -2
```

**Updates**: Daily (triggered by activity/ticket creation, deal changes)

**Alerts**: Account < 5 appears in "At-Risk Accounts" view, Slack alert to sales rep

---

### Workflow 3: Contact Enrichment

**Trigger**: New Contact created

**Process**:
1. Rep adds Contact with name + email
2. Claude attempts enrichment:
   - Phone lookup from email domain / company directory
   - Role inference from email (c-suite, manager, IC)
   - Seniority level estimation
3. Claude shows summary of proposed changes
4. Rep approves or corrects
5. Changes saved to Contact record

**Safety**: Requires human review before any write (not automated)

---

## Integrations & External Systems

### Integration 1: Claude MCP (AI-Driven Operations)

**Direction**: Bidirectional (reads/writes to Notion)

**Tools**:

| Tool | Trigger | Input | Output | Requires Review |
|---|---|---|---|---|
| enrich_contact | Contact created | email, account | phone, role, seniority | YES |
| update_last_contact_date | Activity created | activity_date, contact | contact.last_contacted | NO |
| analyze_activity | Activity created | notes, type | key_outcomes, sentiment, next_steps | NO |
| calculate_health_score | Activity/Ticket/Deal change | account | health_score | NO |

**Error Handling**:
- Enrichment fails silently (if API unavailable, skip enrichment)
- Notifications log failures for review
- All Claude writes are logged to audit_log table

---

### Integration 2: Slack (Notifications)

**Direction**: Outbound only (Notion → Slack)

**Events & Messages**:

| Event | Trigger | Message Template | Recipients |
|---|---|---|---|
| deal_stage_changed | Any stage transition | "{sales_rep} moved {title} to {stage}" | Deal owner, manager |
| deal_won | Stage → WON | "🎉 {title} Won! ${mrr}/month from {account}" | Sales team, Finance |
| critical_ticket | Ticket created + priority=Critical | "🚨 {account}: {title}" | Support team, account owner |
| account_health_low | health_score < 5 | "⚠️ {account} health dropped to {score}/10" | Account owner, manager |

**Frequency**: Real-time

**Error Handling**: Retry 3 times, then log failure for Finance team

---

### Integration 3: Stripe (Billing & Revenue Sync)

**Direction**: Inbound (Stripe → Notion)

**Events & Actions**:

| Event | Action |
|---|---|
| subscription_created | Create Account record if new customer |
| subscription_updated | Update account.mrr to latest subscription amount |
| subscription_canceled | Mark account.status = Churned, set close date |

**Frequency**: Daily sync (runs once per day at 2 AM UTC)

**Error Handling**: Log failures, alert Finance team

**Data Mapping**:
- Stripe customer_id → Account name (if new)
- Stripe subscription amount → Account MRR
- Stripe subscription status → Account status

---

### Integration 4: Email Sync (Planned)

**Status**: Future (manual for now)

**Purpose**: Auto-log emails as Activities

**Expected**: Q3 2025

---

## Permissions & Access Control

### Role-Based Access Model

| Permission | Sales | Support | Finance | Admin |
|---|:---:|:---:|:---:|:---:|
| **Read Accounts** | ✓ | ✓ | ✓ | ✓ |
| **Create Accounts** | ✓ | | | ✓ |
| **Edit own Accounts** | ✓ | | | ✓ |
| **Edit all Accounts** | | | | ✓ |
| **Read Contacts** | ✓ | ✓ | | ✓ |
| **Create Contacts** | ✓ | | | ✓ |
| **Read Deals** | ✓ | ✓ | ✓ | ✓ |
| **Create Deals** | ✓ | | | ✓ |
| **Edit own Deals** | ✓ | | | ✓ |
| **Edit all Deals** | | | | ✓ |
| **Read Tickets** | ✓ | ✓ | | ✓ |
| **Create Tickets** | | ✓ | | ✓ |
| **Edit own Tickets** | | ✓ | | ✓ |
| **View MRR/ARR** | ✓ | ✓ | ✓ | ✓ |
| **Soft Delete** | ✓ | ✓ | | ✓ |
| **Hard Delete** | | | | |
| **Manage Audit Logs** | | | | ✓ |

**Notes**:
- Sales can read Tickets but not create (Support creates)
- Support can read Deals but not edit (Sales owns deal progression)
- Finance can view all revenue data but not modify
- Hard delete is disabled for all roles (audit trail protection)

---

## Constraints & Business Rules

### Data Quality Requirements

**Required Fields** (Cannot be empty):
- Account: name, status
- Contact: name, email, account
- Deal: title, stage, mrr, account
- Activity: title, type, contact, activity_date
- Ticket: title, status, account

**Field Validation**:
- Email must match email format
- Phone must match phone format
- MRR must be > 0
- Status fields cannot be blank
- Dates cannot be in future (except close_date)

---

### Data Retention & Deletion

**Soft Delete** (enabled globally):
- Deleted records remain in database
- Soft-deleted records hidden from views
- Retention period: 90 days after deletion
- After 90 days: automatic permanent deletion

**Hard Delete**: Disabled for all users (even Admin)

**Audit Trail**: Every deletion logged with who, when, why

**Rationale**: Maintains compliance audit trail, allows data recovery

---

### Deletion Cascade Rules

**If Account is deleted**:
- All related Contacts → soft-deleted
- All related Deals → soft-deleted
- All related Tickets → soft-deleted
- Activities → archived (linked records deleted)

**If Contact is deleted**:
- Activities involving contact → archived

**If Deal is deleted**:
- Activities → remain but note deleted deal

**If Ticket is deleted**:
- Activities → remain

---

### Audit Logging

**What's logged**:
- All Claude-initiated writes (tool name, what changed, timestamp)
- All manual record deletions (who, what, when, reason)
- All permission changes
- All enrichment operations

**Retention**: 365 days

**Access**: Admin only

**Format**: Immutable log entries (cannot be edited/deleted)

---

### Compliance & Security

**GDPR Compliance**:
- Personal data fields (email, phone, name) can be exported per request
- Soft delete allows data removal within 30 days
- Audit log tracks personal data access

**SOC2 Light Compliance**:
- Role-based access control enforced
- Audit trails maintained
- Soft delete protects against accidental loss
- No personal data in Notion by design (personal data stays in Stripe)

**Data Encryption**:
- All data encrypted in transit (HTTPS)
- All data encrypted at rest (Notion manages)

---

## Constraints & Performance

**Concurrency**:
- Max 20 simultaneous users supported
- Performance tested and confirmed at this scale

**Query Performance**:
- Acceptable latency: < 2 seconds per query
- Views limited to 10,000 records per view
- Filtering/sorting on indexed properties only

**Scalability Limits** (with current Notion plan):
- Safe up to 10,000 Accounts
- Safe up to 50,000 Deals
- API rate limits: 3 req/sec per workspace

---

## Success Metrics

| Metric | Calculation | Target | Refresh |
|---|---|---|---|
| **Pipeline Visibility** | Total pipeline $ = sum(all open deals) | 100% of deals in system | Real-time |
| **Deal Close Rate** | won / (won + lost) per rep, monthly | >50% win rate | Daily |
| **Account Health** | Score 0-10 based on engagement/support/revenue | >6/10 for Active accounts | Daily |
| **Time to Close** | Median days from deal created to won | <60 days | Weekly |
| **Manual Reporting** | Hours spent on CRM reporting weekly | <1 hour (was 4) | Weekly |
| **Contact Enrichment** | % of contacts with phone + role filled | >85% | Weekly |

---

## Development Phases

### Phase 1: Schema (Notion Structure)
- Create all 5 databases
- Configure all properties, types, relations
- Create all views and filters
- **Checkpoint**: Does empty schema match this document?

### Phase 2: Automations & MCP
- Deploy Claude MCP server
- Implement all 4 tools (enrich_contact, update_last_contact_date, analyze_activity, calculate_health_score)
- Wire Slack integration
- Wire Stripe daily sync
- Audit logging
- **Checkpoint**: Can Claude successfully read/write to Notion?

### Phase 3: Polish & Launch
- Add icons, emojis, colors
- Create view templates
- Train team
- **Checkpoint**: Production-ready?

---

## Notes & Open Decisions

- **Decision**: Deals can be reopened after Won/Lost (reversible by Admin)
- **Decision**: All Claude operations require manual review except last_contacted, analyze_activity, health_score (auto)
- **Decision**: Soft delete only, no hard delete (audit compliance)
- **Open**: Email sync (planned for Q3 2025)
- **Open**: Deal probability → revenue forecast automation (phase 2 expansion)

---

**Document Version**: 1.0  
**Last Updated**: 2025-06-29  
**Maintained By**: Engineering + Product Team
