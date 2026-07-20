# CashCat by Pons ($CASHCAT)
### The canonical launch walkthrough token of pons.family

> *"Every protocol needs one launch that teaches all the others."*

**Contract Address (CA):** `0x6f9b7975430055973734c27d2ddfba2a2a7b13ef`

> ⚠️ **This is a documentation and test token.**

---

# 1. What It Is

**CashCat by Pons** is the canonical documentation token of **pons.family**.

Unlike a conventional test token created solely for protocol validation, `$CASHCAT` exists to demonstrate and explain every stage of a launch on pons.family.

From deployment to graduation, every step of the protocol can be understood by following a single real launch.

Rather than reading disconnected documentation pages, developers can observe the entire lifecycle of one token and understand how every component of the platform works together.

`$CASHCAT` is that reference.

---

# 2. Why CashCat?

The name carries history.

Before pons.family existed, there was another project known as **CashCat**.

It gathered genuine interest and represented the kind of fair launch experience many builders wanted to create.

Unfortunately, after the events surrounding **Noxa**, the project never had the opportunity to become what it was intended to be.

Instead of letting the idea disappear entirely, pons.family preserves it in a different way.

Not as a revival.

Not as an investment.

Not as a continuation of the original project.

But as permanent protocol documentation.

The name lives on—not to speculate—but to teach.

---

# 3. The Story

Every launchpad eventually faces the same challenge.

Documentation can explain contracts.

Documentation can explain functions.

Documentation can explain APIs.

But documentation rarely shows what actually happens during a complete launch.

So pons.family created one.

A launch that exists purely to be observed.

Every transaction.

Every emitted event.

Every restriction.

Every liquidity operation.

Every graduation check.

Every piece of metadata.

Everything that happens to `$CASHCAT` follows the exact flow every future project launched through pons.family will experience.

Instead of reading how the protocol works...

...developers can simply watch it happen.

---

# 4. Launch Walkthrough

The entire lifecycle of a pons.family launch can be understood through `$CASHCAT`.

### Step 1 — Token Creation

The launcher submits:

- name
- symbol
- logo
- description
- socials
- launch configuration

The protocol validates every parameter before deployment.

---

### Step 2 — Deployment

`PonsLaunchFactory` deploys the token deterministically.

The launch is permanently registered on-chain.

---

### Step 3 — Liquidity Initialization

Liquidity is created automatically using the selected DEX configuration.

The launch completes atomically.

---

### Step 4 — Protected Launch

During the protection window the protocol automatically enforces:

- anti-sniping
- maximum wallet limits
- maximum transaction limits
- initial buyer permissions

No administrator interaction is required.

---

### Step 5 — Open Trading

When the restriction period expires, launch protections disappear automatically.

The token behaves as a normal ERC-20.

---

### Step 6 — Graduation

Once the graduation requirements are met, the protocol recognizes the launch as graduated directly from on-chain state.

No manual approval exists.

---

### Step 7 — Permanent Reference

After graduation, the launch becomes a permanent reference implementation for future protocol versions, SDKs, documentation, tutorials, and integrations.

---

# 5. What $CASHCAT Demonstrates

Every stage of a standard pons.family launch.

- Launch configuration
- Parameter validation
- Token deployment
- Liquidity creation
- Anti-snipe protection
- Wallet restrictions
- Transaction limits
- Initial trading
- Graduation logic
- On-chain metadata
- Explorer compatibility
- Frontend integration
- Complete launch lifecycle

Every future launch follows the same architecture.

---

# 6. Contract Technical Reference

$CASHCAT is created and managed by the same production contracts that power every launch on pons.family.

Rather than introducing special logic, it demonstrates the standard launch lifecycle exactly as every future token will experience it.

---

## 6.1 `PonsLaunchFactory` — Launch Orchestration

| Function | Role for $CASHCAT |
|---|---|
| `launchToken(TokenParams, launchConfigId, dexId, salt)` | Deploys `$CASHCAT`, initializes liquidity, creates the launch, and executes the entire launch process atomically |
| `predictTokenAddress(...)` | Demonstrates deterministic token deployment before launch |
| `graduationStatus(token)` | Shows how graduation is determined directly from on-chain liquidity data |
| `getLaunchedToken(token)` | Returns the permanent launch record for `$CASHCAT` |
| `addDexConfig` / `addLaunchConfig` | Registers the launch configurations used throughout the documentation |
| `setLaunchEnabled` / `setWhitelistedLauncher` | Demonstrates protocol-level launch permissions |

---

## 6.2 `PonsLauncherToken` — Launch Behavior

| Function | Role for $CASHCAT |
|---|---|
| `constructor(...)` | Creates the token supply, stores metadata, and initializes the launch state |
| `_update(from, to, value)` | Demonstrates launch protection, anti-sniping, and transfer restrictions |
| `liquidityPool()` | Resolves the canonical liquidity pool created during launch |
| `maxWalletLimit()` / `maxTxLimit()` | Demonstrates active wallet and transaction restrictions |
| `setInitialBuyRecipient(address)` | Allows the protocol's initial seed purchase during launch |
| `socials()` / `getTokenInfo()` | Returns metadata used throughout the documentation examples |
| `_isPairPool(candidate)` | Detects valid liquidity pools created by the protocol |

---

# 7. Why It Matters

`$CASHCAT` serves multiple purposes simultaneously.

- **Protocol documentation** — the canonical example used throughout pons.family.
- **Developer education** — demonstrates the complete launch process from beginning to end.
- **Reference implementation** — every SDK, tutorial, guide, and integration can point to the same launch.
- **Regression testing** — future protocol versions can recreate `$CASHCAT` to verify behavioral compatibility.
- **Infrastructure validation** — lockers, launch configurations, DEX integrations, and protocol upgrades can all be tested against a known reference launch.

---

# 8. The Future of $CASHCAT

To be completely clear:

**`$CASHCAT` is a documentation and test token.**

It has **no holder utility**.

It is **not intended for speculation**.

Its purpose is to become the permanent educational reference for pons.family.

Every tutorial.

Every guide.

Every SDK example.

Every frontend.

Every explorer.

Every audit.

Every future launch.

Can reference one complete, canonical example.

`$CASHCAT`.

---

> *"Some tokens are launched to build markets. Others are launched to build understanding."*

**CashCat by Pons ($CASHCAT)**  
*The canonical launch walkthrough of pons.family.*
