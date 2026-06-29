# Best Practices for Building Notion Systems with MCP

A professional workflow for designing, documenting, and building Notion systems using Claude and the Model Context Protocol (MCP).

---

## Overview

Building a robust Notion system requires clear requirements, explicit architecture, and disciplined implementation. This guide provides a four-stage process that prevents AI confusion, creates a single source of truth, and ensures the MCP layer is built from explicit specifications rather than assumptions.

### Why This Process?

- **Prevents scope creep**: Grilling forces ruthless MVP definition
- **Creates a contract**: The stateful representation acts as a blueprint both humans and AI can follow
- **Enables phased delivery**: Breaking the build into stages catches structural problems early
- **Maintains discipline**: Each stage uses specific skills to stay focused and documented

---

## The Four-Stage Process

```
Stage 1: Grilling        → Requirements locked down
         ↓
Stage 2: Domain Modeling → Stateful representation (.md + .yaml)
         ↓
Stage 3: Planning        → Phased implementation plan
         ↓
Stage 4: Building        → Execute in 3 phases (Schema → Automation → Polish)
```

### Stage 1: Grilling (Requirements Definition)

**Skill**: `/grilling`

**Goal**: Ruthlessly define the system scope and extract all requirements before any design work.

**Output**: A grilling transcript documenting:
- System purpose and business goals
- Key entities (what are you tracking?)
- User personas (who uses this?)
- Workflows (what do they do with the data?)
- Integration points (where does Claude add value?)
- Constraints (deadlines, budget, team size)
- Success metrics (how do you know this works?)

**Key Principle**: Say "no" to out-of-scope features. Document rejected ideas for Phase 2.

**Deliverable**: A text record of questions answered and decisions made.

---

### Stage 2: Domain Modeling (Stateful Representation)

**Skill**: `/Notion:database-query` or manual documentation using the format below

**Goal**: Create an explicit, structured representation of the entire Notion system architecture.

**Output**: Two linked files:
1. **`SYSTEM_ARCHITECTURE.yaml`** — Machine-readable schema
2. **`SYSTEM_ARCHITECTURE.md`** — Human-readable documentation

This is your **single source of truth**. Every tool, database, property, and rule is documented here before MCP implementation begins.

---

## Stateful Representation Format

### File 1: `SYSTEM_ARCHITECTURE.yaml`

```yaml
system:
  name: "Company CRM"
  description: "Customer relationship management system"
  icon: "🚀"
  version: "1.0"

databases:
  accounts:
    display_name: "Accounts"
    description: "Companies we work with"
    icon: "🏢"
    emoji_color: "blue"
    properties:
      name:
        type: "title"
        description: "Company legal name"
      status:
        type: "select"
        description: "Account lifecycle stage"
        options:
          - name: "Prospect"
            color: "blue"
          - name: "Active"
            color: "green"
          - name: "Churned"
            color: "red"
      industry:
        type: "select"
        description: "Industry classification"
        options:
          - name: "SaaS"
          - name: "Healthcare"
          - name: "Finance"
      contact_count:
        type: "rollup"
        description: "Number of contacts at this account"
        relation_target: "contacts"
        rollup_formula: "count()"
      contacts:
        type: "relation"
        description: "People at this company"
        target_database: "contacts"
        target_property: "account"
    views:
      - name: "Active Accounts"
        type: "table"
        visible_properties: ["name", "status", "industry", "contact_count"]
        filters:
          - property: "status"
            condition: "equals"
            value: "Active"
    templates:
      - name: "New Account"
        description: "Template for onboarding a new account"
        default_properties:
          status: "Prospect"

  contacts:
    display_name: "Contacts"
    description: "Individual people at accounts"
    icon: "👤"
    properties:
      name:
        type: "title"
        description: "Contact full name"
      email:
        type: "email"
        description: "Primary work email"
      phone:
        type: "phone_number"
        description: "Primary work phone"
      account:
        type: "relation"
        description: "Account this person belongs to"
        target_database: "accounts"
      role:
        type: "select"
        options:
          - name: "Decision Maker"
          - name: "Influencer"
          - name: "End User"
      last_contacted:
        type: "date"
        description: "Last interaction date (Claude updates this)"
      activity_count:
        type: "rollup"
        relation_target: "activities"
        rollup_formula: "count()"
    views:
      - name: "Decision Makers"
        type: "table"
        filters:
          - property: "role"
            condition: "equals"
            value: "Decision Maker"

  activities:
    display_name: "Activities"
    description: "Interactions: calls, emails, meetings"
    icon: "📞"
    properties:
      name:
        type: "title"
        description: "Activity summary"
      type:
        type: "select"
        options:
          - name: "Call"
          - name: "Email"
          - name: "Meeting"
      contact:
        type: "relation"
        target_database: "contacts"
      account:
        type: "relation"
        target_database: "accounts"
      date:
        type: "date"
        description: "When the activity occurred"
      notes:
        type: "rich_text"
        description: "Activity details (Claude populates this)"
      synced_at:
        type: "created_time"

automations:
  - name: "enrich_contact_on_create"
    trigger: "contact_created"
    description: "When a new contact is created, Claude enriches email/phone data"
    mcp_tool: "enrich_contact"
    validation:
      requires: ["email", "account"]
      enriches: ["phone", "role"]
  
  - name: "log_activity"
    trigger: "activity_created"
    description: "When an activity is logged, Claude extracts key insights"
    mcp_tool: "analyze_activity"
    validation:
      requires: ["type", "contact"]
      optional: ["notes"]

integrations:
  claude_mcp:
    description: "MCP server for AI-driven data operations"
    tools:
      - name: "enrich_contact"
        description: "Fill in missing contact information"
        writes_to: ["contacts"]
        requires_review: true
      
      - name: "analyze_activity"
        description: "Extract insights from activity notes"
        writes_to: ["activities"]
        requires_review: false

constraints:
  - "No deleting historical records (soft-delete only)"
  - "Claude must show summary before modifying more than 5 records"
  - "All write operations logged in audit_log table"
```

### File 2: `SYSTEM_ARCHITECTURE.md`

```markdown
# System Architecture: Company CRM

## Overview

This document describes the structure, workflows, and integration points for the Company CRM system built on Notion and Claude MCP.

**System Purpose**: Manage customer relationships, track interactions, and surface sales insights through AI-assisted data enrichment and analysis.

---

## Databases

### Accounts

**Icon**: 🏢 | **Color**: Blue

**Purpose**: Single record per company we do business with.

**Properties**:
- **name** (Title): Company legal name. Used as the database lookup key.
- **status** (Select): Account lifecycle. Values: Prospect, Active, Churned
- **industry** (Select): Industry classification for segmentation
- **contact_count** (Rollup): Automatically counts related contacts
- **contacts** (Relation): Links to all people at this company

**Views**:
- **Active Accounts** (table): Shows only status="Active", with name, industry, contact count visible
- **By Industry** (table): Grouped view for sales team segmentation

**Validations**:
- Name is required
- Status cannot be blank

---

### Contacts

**Icon**: 👤 | **Color**: Purple

**Purpose**: Individual people we interact with.

**Properties**:
- **name** (Title): Full name
- **email** (Email): Primary work email
- **phone** (Phone): Primary work phone. *Often enriched by Claude*
- **account** (Relation): Parent company
- **role** (Select): Decision Maker, Influencer, End User
- **last_contacted** (Date): Last interaction. *Updated by Claude on activity creation*
- **activity_count** (Rollup): Counts linked activities

**Views**:
- **Decision Makers** (table): Filtered to role="Decision Maker" only
- **By Account** (gallery): Grouped by parent company

**Validations**:
- Name and email required
- Must be linked to an account

---

### Activities

**Icon**: 📞 | **Color**: Green

**Purpose**: Log every interaction (call, email, meeting).

**Properties**:
- **name** (Title): Activity summary (e.g., "Budget discussion with Sarah")
- **type** (Select): Call, Email, Meeting
- **contact** (Relation): Person involved
- **account** (Relation): Company involved
- **date** (Date): When it happened
- **notes** (Rich Text): What was discussed. *Claude enriches with key insights*
- **synced_at** (Created Time): When the record was created

**Views**:
- **This Week** (table): Shows activities from last 7 days
- **By Contact** (timeline): Shows interactions chronologically per contact

**Validations**:
- Type is required
- Must link to at least one contact

---

## Automations & Validations

### Automation 1: Enrich Contact on Create

**Trigger**: New contact created  
**MCP Tool**: `enrich_contact`  
**Behavior**: When a contact is added, Claude attempts to fill in missing phone numbers and infer role based on email domain/company research  
**Validation Rules**:
- Email is required (can't enrich without it)
- Only enriches phone if missing
- Sets role to "Unknown" if inference fails

**Review Required**: Yes (human reviews enrichments before saving)

---

### Automation 2: Log Activity Insights

**Trigger**: New activity created  
**MCP Tool**: `analyze_activity`  
**Behavior**: When an activity is logged, Claude reads the notes and extracts:
- Key decisions made
- Next steps
- Risks/blockers
- Stakeholder sentiment  

**Writes To**: Appends insights to the activity notes in a structured format

**Review Required**: No (purely additive, doesn't modify core fields)

---

## Claude MCP Integration Points

### Tool: `enrich_contact`
- **Reads from**: Email provider APIs (if available), LinkedIn, company website
- **Writes to**: contact.phone, contact.role
- **Safety**: Shows Claude's proposed changes before applying
- **Error handling**: Fails gracefully if enrichment not possible

### Tool: `analyze_activity`
- **Reads from**: activity.notes, activity.type, linked contact
- **Writes to**: activity.notes (appends insights)
- **Safety**: Purely appends; never overwrites original notes
- **Error handling**: Skips analysis if notes are empty

---

## Constraints & Guidelines

1. **Historical Records**: Never delete contacts or activities. Use soft-delete via a "deleted" boolean property.
2. **Bulk Operations**: If Claude will modify >5 records, always require a summary review first.
3. **Audit Trail**: All Claude-initiated writes are logged in a separate audit_log table with timestamp, user, change, and reason.
4. **Data Quality**: Enrichment operations must maintain >90% accuracy to be trusted.

---

## Success Metrics

- Contact data 85%+ complete (email + phone populated)
- Activity notes analyzed within 5 minutes of creation
- Sales team reporting 20% faster deal progression due to AI insights
```

---

## Stage 3: Planning (Implementation Plan)

**Skill**: `/superpowers:writing-plans`

**Goal**: Create a phased, executable implementation plan based on the stateful representation.

**Output**: A detailed plan breaking the build into 3 phases:

### Phase 1: Schema (Notion Database Structure)
- Create each database with correct properties and types
- Establish all relations and rollups
- Create views and filters
- Validate all data types match the YAML spec
- **Checkpoint**: Does the empty schema look right?

### Phase 2: Automation & MCP Tooling
- Implement MCP server and tools
- Wire up Claude-to-Notion write operations
- Add validation rules
- Create audit logging
- **Checkpoint**: Can Claude successfully read and write to Notion?

### Phase 3: Polish & Optimization
- Add icons, emoji, colors
- Create view templates
- Build button automations (if needed)
- Performance tuning
- **Checkpoint**: Is this production-ready?

**Key**: Do NOT merge phases. Phase 1 must be complete before Phase 2 starts.

---

## Stage 4: Building (Execution)

**Skill**: `/superpowers:executing-plans` or `/run`

**Process**:
1. Execute Phase 1 following the YAML spec exactly
2. Verify Phase 1 against checklist before proceeding
3. Execute Phase 2, using SYSTEM_ARCHITECTURE.md to guide MCP tool design
4. Verify Phase 2 (test read/write operations)
5. Execute Phase 3 for UX polish

**MCP Tool Design**: Each tool in `integrations.mcp_tools` becomes a real function that:
- Takes structured input (contact object, activity notes)
- Performs Claude reasoning
- Returns output in expected format
- Writes to Notion via Notion MCP server
- Logs audit trail

---

## Checklist by Stage

### Stage 1: Grilling ✓
- [ ] System purpose is clear and bounded
- [ ] Key entities defined (accounts, contacts, activities)
- [ ] User workflows documented
- [ ] Integration points identified
- [ ] Out-of-scope features explicitly listed
- [ ] Success metrics defined

### Stage 2: Domain Modeling ✓
- [ ] SYSTEM_ARCHITECTURE.yaml is complete
- [ ] SYSTEM_ARCHITECTURE.md matches the YAML
- [ ] All databases documented
- [ ] All properties and types specified
- [ ] All automations described
- [ ] All MCP tools have clear contracts (inputs/outputs)
- [ ] Constraints and validations documented

### Stage 3: Planning ✓
- [ ] Phase 1 (Schema) plan is detailed
- [ ] Phase 2 (Automation) plan includes MCP tool specs
- [ ] Phase 3 (Polish) plan is clear
- [ ] Checkpoint criteria defined for each phase
- [ ] Risk mitigations identified

### Stage 4: Building - Phase 1 ✓
- [ ] All databases created in Notion
- [ ] All properties match SYSTEM_ARCHITECTURE.yaml
- [ ] All relations configured
- [ ] All rollups working correctly
- [ ] All views created and filters applied
- [ ] Empty schema validated visually
- [ ] **Checkpoint: Does it match the spec?**

### Stage 4: Building - Phase 2 ✓
- [ ] MCP server deployed
- [ ] All MCP tools implemented per spec
- [ ] Read operations tested (Claude can query data)
- [ ] Write operations tested (Claude can modify records)
- [ ] Validation rules enforced
- [ ] Audit logging working
- [ ] **Checkpoint: Can Claude successfully interact?**

### Stage 4: Building - Phase 3 ✓
- [ ] Icons and emojis applied
- [ ] View templates created
- [ ] Performance optimized (queries fast)
- [ ] Documentation updated
- [ ] Team trained
- [ ] **Checkpoint: Is this ready for production?**

---

## Best Practices

### 1. Keep the Stateful Representation Fresh
Every change to Notion structure goes into SYSTEM_ARCHITECTURE.yaml + .md first. Use the representation as the source of truth, not Notion directly.

### 2. Version Your Schema
Tag releases as v1.0, v1.1, v2.0 when making structural changes. Never ship a schema change without updating the YAML.

### 3. Test Automations on 2-3 Records
Before running a Claude automation on your entire database, test it on a small sample. If it fails, you catch it early.

### 4. Require Review for Destructive Operations
If Claude is modifying >5 records or writing sensitive data (salary, customer secret), always show a summary before executing.

### 5. Separate Reads from Writes
MCP tools that only read data don't need review. Tools that modify data should require human approval.

### 6. Log Everything
Every Claude write operation should go into an audit_log table with: timestamp, what changed, why, who triggered it.

### 7. Use Relations, Not Formulas
Prefer Notion relations + rollups over complex formulas. Relations are easier to query via MCP and less likely to break.

### 8. Icon Consistency
- Databases: Domain emoji (🏢 for company, 👤 for person, 📞 for activity)
- Properties: Property-type emoji (🔗 for relation, 🧮 for rollup)
- Views: Action emoji (🔍 for filtered, 📅 for timeline)

---

## Common Pitfalls to Avoid

❌ **Skipping grilling**: "I know what we need"  
→ You don't. Requirements hide until you ask them out loud.

❌ **Building without the stateful representation**  
→ AI will invent details and you'll have to rebuild.

❌ **Monolithic builds**: "Let's just build the whole thing"  
→ If Phase 1 is wrong, Phase 2-3 are wasted effort.

❌ **Automating without testing**  
→ Test on 2-3 records. Always.

❌ **Treating SYSTEM_ARCHITECTURE.md as documentation**  
→ It IS the spec. Update it before updating Notion. Notion follows the spec, not the reverse.

❌ **Ignoring constraints and validation**  
→ "Validation can come later" leads to bad data. Build it in from Phase 1.

---

## When to Iterate

**After Phase 1**: If the schema doesn't match your mental model, adjust the YAML and rebuild Phase 1. This is cheap.

**After Phase 2**: If MCP tools don't work as expected, refine the tool contracts in SYSTEM_ARCHITECTURE.yaml and rebuild.

**During Phase 3**: UI tweaks (colors, icons, view names) can be done anytime without breaking anything.

**After Production**: Major features belong in the next version (v1.1, v2.0). Don't bolt them onto Phase 3.

---

## Tools & Skills Summary

| Stage | Skill | Output |
|-------|-------|--------|
| Grilling | `/grilling` | Requirements transcript |
| Domain Modeling | (manual + `/Notion:database-query`) | SYSTEM_ARCHITECTURE.yaml + .md |
| Planning | `/superpowers:writing-plans` | 3-phase implementation plan |
| Building | `/superpowers:executing-plans` or `/run` | Deployed Notion system + MCP |

---

## Next Steps for Your Project

1. **Schedule grilling session** with stakeholders using `/grilling`
2. **Lock requirements** and document them
3. **Create SYSTEM_ARCHITECTURE.yaml + .md** from grilling output
4. **Get stakeholder sign-off** on the stateful representation
5. **Run `/superpowers:writing-plans`** to create the phased plan
6. **Execute Phase 1** (Schema)
7. **Verify Phase 1** against SYSTEM_ARCHITECTURE.yaml
8. **Execute Phase 2** (Automation + MCP)
9. **Verify Phase 2** (test read/write)
10. **Execute Phase 3** (Polish)

---

**Document Last Updated**: 2026-06-29  
**Version**: 1.0  
**Status**: Ready for use
