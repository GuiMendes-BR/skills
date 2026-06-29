---
name: designing-notion-system
description: Use when designing a Notion system and want grilling questions pre-shaped to produce SYSTEM_ARCHITECTURE.yaml and SYSTEM_ARCHITECTURE.md directly
---

# Designing Notion System

## Overview

Standard grilling produces narrative transcripts. Converting transcripts to structured architecture docs takes ~7 hours of manual work (formalize schema, permissions, workflows, integrations, constraints).

This skill combines grilling methodology with architecture-aware questions so answers feed directly into machine-readable YAML and human-readable markdown. **Output: Ready-to-use SYSTEM_ARCHITECTURE.yaml + SYSTEM_ARCHITECTURE.md in a single session.**

Core principle: Ask grilling questions in an order that builds the schema incrementally, capturing each answer in YAML form as you go.

---

## When to Use

- **Designing a new Notion system** (CRM, knowledge base, project tracker, etc.)
- **Stakeholder input is available** (you can ask and get answers live)
- **You want architecture docs directly** (not a transcript to translate later)
- **You want to catch ambiguities early** (structured questions surface integration/permission gaps)

**NOT for:** Documenting an existing Notion system (use domain-modeling skill instead)

---

## The Flow

```
Phase 1: Core Entities & Properties
   ↓
Phase 2: Relationships & Cardinality
   ↓
Phase 3: Views & Filtering
   ↓
Phase 4: Workflows & State Machines
   ↓
Phase 5: Integrations & External Systems
   ↓
Phase 6: Permissions & Access Control
   ↓
Phase 7: Constraints & Business Rules
   ↓
Phase 8: Metrics & Reporting
   ↓
Output: SYSTEM_ARCHITECTURE.yaml + SYSTEM_ARCHITECTURE.md
```

Each phase builds on the previous. **Do not skip phases** — they uncover dependencies that reshape earlier decisions.

---

## Phase-by-Phase Questions

### Phase 1: Core Entities & Properties (30 min)

**Goal:** Define what "things" the system tracks and their fields.

**Questions in order:**

1. **System Name & Purpose**
   - "What's this system called?"
   - "In one sentence, what problem does it solve?"
   - *Record: system.name, system.description, system.icon, system.version*

2. **What are the main entities you track?** (Databases in Notion)
   - List 3-5 primary "things": Accounts? Contacts? Deals? Projects? Tickets?
   - *Record: databases[].name*

3. **For EACH entity, ask:**
   
   **a) What's the primary display field?** (What name/title identifies one record?)
   - Contact → "name", Deal → "title", Project → "project_name"
   - *Record: databases[X].properties[title].type = "title"*
   
   **b) What other properties does it have?** (Walk through a typical record)
   - "If I'm looking at a Contact, what information do I see?"
   - Capture: name, type (email, phone, select, date, etc.), description
   - *Record: databases[X].properties[field].type*
   
   **c) Which fields are required?** 
   - *Record: databases[X].properties[field].required = true*
   
   **d) For SELECT fields, what are the options?**
   - Status: Prospect, Active, Churned
   - Role: Decision Maker, Influencer, End User
   - *Record: databases[X].properties[field].options[]*.

4. **Rollups & Counts**
   - "Do you want to see counts? E.g., 'How many Contacts does this Account have?'"
   - *Record: databases[X].properties[count_field].type = "rollup"*

---

### Phase 2: Relationships & Cardinality (20 min)

**Goal:** Formalize how entities connect.

**Questions:**

1. **Which entities link to which?**
   - "Does Contact belong to an Account?" → Yes (many contacts per account)
   - "Does Deal belong to an Account?" → Yes
   - "Can a Deal have multiple Contacts?" → Maybe (decision to make)
   - *Record: databases[X].properties[relation_field] with target_database, cardinality*

2. **For each relationship:**
   - "Is this one-to-one, one-to-many, or many-to-many?"
   - "Is the relationship bidirectional? (Do both sides need a link property?)"
   - *Record: cardinality, bidirectional = true/false*

3. **Soft delete cascade:**
   - "If I delete an Account, what happens to its Contacts and Deals?"
   - Orphan them? Cascade delete? Prevent deletion?
   - *Record: constraints.cascade_delete (per entity)*

---

### Phase 3: Views & Filtering (15 min)

**Goal:** Define how users query and organize data.

**Questions:**

1. **For each database, what views does the user need?**
   - "What's the first view a sales rep opens?" → "All Deals" or "My Deals"?
   - "What filters matter?" → Status, Owner, Date Range, Account, Stage
   - *Record: databases[X].views[].name, filters[], sort_by, group_by*

2. **View-specific:**
   - "Do you need timeline view? Kanban? Gallery?"
   - "Which properties should be visible in each view?"
   - *Record: databases[X].views[].type, visible_properties[]*

---

### Phase 4: Workflows & State Machines (30 min)

**Goal:** Formalize how data moves through the system (most important phase for catching ambiguities).

**Questions:**

1. **What's the primary workflow?**
   - "Walk me through a typical day for a sales rep. How does a deal get created and progress?"
   - Prospect → Qualified → Proposal → Won/Lost
   - *Record: automations[].trigger, automations[].workflow*

2. **For each workflow, ask state transition questions:**
   - "Can a deal move backward? (Re-open a lost deal?)"
   - "Are there intermediate states? (e.g., Proposal → Under Review → Accepted?)"
   - "Who can move a deal forward? (Any rep or only owner?)"
   - *Record: automations[].transitions[from][to], required_role, validation*

3. **Activity workflows:**
   - "When someone creates an Activity record, should it auto-update any other field?"
   - Example: "Creating an Activity should update Contact.last_contacted"
   - *Record: automations[].trigger, automations[].action*

4. **Ambiguity Resolution (most critical):**
   - "If Support closes a Ticket, should it auto-close the related Deal?"
   - "If a Deal is Won, should any notifications fire?"
   - "Can Contacts move between Accounts?"
   - *Record: automations[] with clear trigger, condition, action*

---

### Phase 5: Integrations & External Systems (20 min)

**Goal:** Define what data flows in and out, and how.

**Questions:**

1. **What external systems need to sync with Notion?**
   - Slack? Stripe? Gmail? Salesforce? Analytics tools?
   - *Record: integrations[].name, integrations[].description*

2. **For each integration:**
   - **Direction:** Inbound (system → Notion), Outbound (Notion → system), or bidirectional?
   - **Events:** Which events trigger the integration?
     - "When a Deal moves to Won, should Slack be notified?"
     - "When Stripe records a payment, should it update the Deal?"
   - **Data mapping:** What Notion field maps to what external field?
   - **Frequency:** Real-time, daily sync, manual?
   - **Error handling:** What if sync fails? Retry? Alert?
   - *Record: integrations[].direction, integrations[].events[], integrations[].frequency, integrations[].error_handling*

3. **Claude/MCP Integration:**
   - "What should Claude automate?"
   - "Which fields should Claude be allowed to modify?"
   - "Which operations require human review before executing?"
   - *Record: integrations.claude_mcp.tools[].name, integrations.claude_mcp.tools[].requires_review*

---

### Phase 6: Permissions & Access Control (20 min)

**Goal:** Define who can read/create/edit what.

**Questions:**

1. **Define roles:**
   - "What are the user types in your company?" (Sales, Support, Finance, Admin)
   - *Record: roles[].name*

2. **For each role, ask:**
   - "Can this role READ [entity]?" (Accounts, Contacts, Deals, Tickets)
   - "Can this role CREATE [entity]?"
   - "Can this role EDIT [entity]? (Own records only or all?)"
   - "Can this role DELETE [entity]? (Hard or soft delete?)"
   - *Record: roles[].permissions.*

3. **Edge cases:**
   - "Can Sales see Support Tickets?"
   - "Can Support modify Deals?"
   - "Can Finance see customer revenue but not contact info?"
   - *Record: roles[].permissions with exceptions*

4. **Field-level permissions (if needed):**
   - "Are there sensitive fields only Management can see? (e.g., Deal discount %)"
   - *Record: properties[].visible_to_roles[]*

---

### Phase 7: Constraints & Business Rules (15 min)

**Goal:** Enforce data quality and compliance.

**Questions:**

1. **Required fields:**
   - "Can you create a Deal without an Account?" → No (Deals require Accounts)
   - "Can you create a Contact without an email?" → Yes (email is optional)
   - *Record: databases[X].properties[Y].required = true/false*

2. **Deletion & data retention:**
   - "Can records be hard-deleted or only soft-deleted?"
   - "How long are soft-deleted records kept?" (30 days? 90 days? Forever?)
   - *Record: constraints.hard_delete_allowed, constraints.soft_delete_retention*

3. **Compliance & audit:**
   - "Do you need an audit log of who changed what and when?"
   - "GDPR requirements? CCPA? SOC2?"
   - *Record: constraints.audit_log, constraints.compliance*

4. **Data quality:**
   - "Are there fields that should be unique? (e.g., Email, Account Name)"
   - "Are there fields that need validation? (e.g., Phone format, URL format)"
   - *Record: databases[X].properties[Y].validation*

---

### Phase 8: Metrics & Reporting (20 min)

**Goal:** Define success metrics and dashboards.

**Questions:**

1. **Success metrics:**
   - "How will you measure if this CRM is working?"
   - Examples: Pipeline health, deal close rates, customer health, response times
   - *Record: success_metrics[].name, success_metrics[].calculation*

2. **Reporting requirements:**
   - "What dashboards do users need?"
   - "What data should be on each dashboard?"
   - "How often should reports refresh? (Real-time or daily?)"
   - *Record: reports[].name, reports[].metrics[], reports[].refresh_frequency*

3. **Roll-up metrics:**
   - "Should you see pipeline $ by stage? By rep? By month?"
   - *Record: reports[].grouping_dimensions*

---

## Output Generation

After Phase 8, immediately generate:

1. **SYSTEM_ARCHITECTURE.yaml**
   - Machine-readable schema (use format from BEST_PRACTICES_FOR_BUILDING_NOTION_SYSTEMS_WITH_MCP.md)
   - Verify: all databases, properties, relationships, automations, integrations documented

2. **SYSTEM_ARCHITECTURE.md**
   - Human-readable narrative (use template from BEST_PRACTICES guide)
   - Include: overview, all databases with descriptions, automations, integrations, constraints
   - Verify: matches the YAML exactly

3. **Ambiguity Resolution Log**
   - Document decisions made during grilling
   - Record edge cases and open questions
   - Example: "Decided: Deals can only be owned by one Sales rep. Open: Can a Deal be reassigned after Won status?"

---

## Phase Dependencies & Sequencing

**Critical:** Do not reorder phases. Dependencies:

- **Phase 1 → Phase 2:** Need entities defined before linking them
- **Phase 2 → Phase 3:** Need relationships to build meaningful views
- **Phase 3 → Phase 4:** Views inform what workflows matter
- **Phase 4 → Phase 5:** Workflows determine what integrations are needed
- **Phase 5 → Phase 6:** Integration points inform permission boundaries
- **Phase 6 → Phase 7:** Permissions shape constraint design
- **Phase 7 → Phase 8:** Constraints define what metrics are measurable

**If Phase X reveals Phase Y was wrong:** Go back and rebuild Phase Y. Do NOT proceed until consistent.

---

## Common Ambiguities to Surface

These typically hide until you ask structured questions. **Surface and resolve:**

| **Ambiguity** | **Questions to Ask** | **Record in** |
|---|---|---|
| **Soft delete cascade** | "If Account deleted, what happens to its Deals?" | constraints.cascade_delete |
| **Workflow backward transitions** | "Can a Deal move from Won back to Proposal?" | automations[].transitions |
| **Cross-team access** | "Can Sales see Support Tickets?" | roles[].permissions |
| **Integration conflicts** | "Stripe updates revenue; Notion also tracks $ in Deal. Which is source of truth?" | integrations[].notes |
| **Permission granularity** | "Can Finance see Deal discount % but not other users?" | properties[].visible_to_roles |
| **Audit requirements** | "Do you need who-changed-what logs?" | constraints.audit_log |
| **Concurrency** | "How many simultaneous users? Will Notion keep up?" | system.scale |

If an ambiguity emerges: **Ask it. Write down the decision. Record it in YAML.** Do not guess.

---

## Checklist After Session

- [ ] All 8 phases completed
- [ ] SYSTEM_ARCHITECTURE.yaml generated and valid
- [ ] SYSTEM_ARCHITECTURE.md matches YAML exactly
- [ ] Ambiguity Resolution Log documented
- [ ] No "TBD" or "TK" fields remaining in YAML
- [ ] All relationships have clear cardinality
- [ ] All workflows have defined state transitions
- [ ] All integrations have direction, events, and frequency specified
- [ ] All roles have explicit permissions (read, create, edit, delete)
- [ ] All constraints documented (required fields, deletion rules, audit, compliance)
- [ ] Success metrics are measurable (not vague like "good pipeline visibility")
- [ ] Stakeholders review and sign off on architecture

---

## When Ambiguities Block Progress

If you cannot answer a phase question:
- **Do not guess.** Document as open decision: "OPEN: Decide whether Deals can be reassigned after Won"
- **Mark in YAML with `# TODO`** comment
- **Continue to next phase.** Return to Phase X after gathering more info.
- **Before Phase 8 ends:** All TODOs must be resolved or escalated to stakeholders.

---

## Real-World Impact

**Standard grilling + manual translation:** 7-10 hours over multiple sessions, high risk of rework.

**Notion System Design:** 3-4 hours in one session, architecture docs ready to hand to engineering.

**Benefit:** Structured questions surface integration/permission/workflow ambiguities that narrative grilling misses entirely.
