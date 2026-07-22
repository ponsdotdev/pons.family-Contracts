# Pepons by Pons ($PEPONS)
### The canonical launch walkthrough mascot token of pons.family

> *"Green. Motionless. Impossible to rug — mostly because nothing about it ever moves fast enough to get caught."*

**Contract Address (CA):** `0x0000000000000000000000000000000000000000`

> ⚠️ **This is a documentation and test token. No holder utility. No promises. No lily pads included.**

---

# 1. What It Is

**Pepons by Pons** is the canonical mascot and documentation token of **pons.family**.

Every protocol needs a face. Most launchpads pick a dog, a dog in a hat, or another dog in a slightly different hat. pons.family picked a frog — an animal whose entire evolutionary strategy is "stay still until the danger loses interest," which, coincidentally, is also the best possible description of a well-designed on-chain security mechanism.

`$PEPONS` exists to demonstrate every stage of a launch on pons.family, wrapped around a mascot whose defining trait is total calm while everything around it happens.

From deployment to graduation, every step of the protocol can be understood by following a single real launch — guarded, quite literally in the branding, by an amphibian that never flinches.

---

# 2. Why Pepons?

Every launchpad has a story about why its mascot looks the way it does. Here's ours.

According to internal pons.family lore (written down for the first time right here, so consider this the primary source), the frog was chosen after the team spent a full week debating anti-snipe mechanisms, until someone pointed out that nature had already solved this problem ages ago: don't twitch, don't react to every stimulus, wait for the storm to pass on its own.

A frog doesn't chase the predator and it doesn't panic-flee. It just stays perfectly still until the situation stabilizes itself.

Which, on reflection, turns out to be a surprisingly accurate metaphor for a well-designed launch: wallet caps, transaction limits, and anti-sniping don't stop someone from *wanting* to snipe the first block — they just make the attempt pointless and unrewarding, the same way staying motionless makes a movement-based predator's attack useless.

So the mascot stuck. Not because it's cute (though it is), but because the metaphor had already done most of the documentation's job before a single line was written.

---

# 3. The Story

Every launchpad eventually needs to explain its protections in a way that isn't just a bullet list of Solidity function names.

Documentation can explain contracts.

Documentation can explain functions.

Documentation can explain APIs.

Documentation rarely gives people something to actually picture when they hear "anti-snipe protection" or "maximum wallet limit."

So pons.family gave it a face: a small, green, unshakeably calm amphibian, launched under completely normal, unprotected conditions to see what would happen — and immediately covered in every protective mechanism the protocol has to offer the moment real deployment began.

Every transaction.

Every emitted event.

Every restriction.

Every liquidity operation.

Every graduation check.

All observable, on-chain, in public — because a frog only blends in as long as nobody looks too closely. Same idea here. The protections aren't a black box; they're the whole point of the demo.

---

# 4. Launch Walkthrough

The entire lifecycle of a pons.family launch can be understood through `$PEPONS`.

### Step 1 — Token Creation

The launcher submits:

- name
- symbol
- logo (a frog, ideally with an unreadable expression)
- description
- socials
- launch configuration

The protocol validates every parameter before deployment — the one thing it can't validate is whether your mascot radiates enough zen calm to discourage panic selling. That part's on the art department.

---

### Step 2 — Deployment

`PonsLaunchFactory` deploys the token deterministically.

The launch is permanently registered on-chain, perfectly still and ready, before a single trade has happened.

---

### Step 3 — Liquidity Initialization

Liquidity is created automatically using the selected DEX configuration.

The launch completes atomically — no gap between "liquidity exists" and "liquidity is protected," which is exactly the window a motionless frog never gives a movement-tracking predator either.

---

### Step 4 — Protected Launch

During the protection window the protocol automatically enforces:

- anti-sniping
- maximum wallet limits
- maximum transaction limits
- initial buyer permissions

No administrator interaction is required. The frog doesn't need a bodyguard. That's the entire design philosophy.

---

### Step 5 — Open Trading

When the restriction period expires, launch protections disappear automatically.

The token behaves as a normal ERC-20 — the calm, metaphorically, snaps into action once the early-launch danger window (the one snipers actually exploit) has passed.

---

### Step 6 — Graduation

Once the graduation requirements are met, the protocol recognizes the launch as graduated directly from on-chain state.

No manual approval exists. Nobody has to vouch for the frog. The chain either sees the liquidity thresholds met, or it doesn't.

---

### Step 7 — Permanent Reference

After graduation, the launch becomes a permanent reference implementation for future protocol versions, SDKs, documentation, tutorials, and integrations.

`$PEPONS` becomes the mascot every future pons.family launch gets compared to: did it stay as composed under pressure as the frog did?

---

# 5. What $PEPONS Demonstrates

Every stage of a standard pons.family launch, narrated by an animal that takes stillness very seriously.

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

Every future launch follows the same architecture. Not every future launch will have as zen a mascot.

---

# 6. Contract Technical Reference

$PEPONS is created and managed by the same production contracts that power every launch on pons.family.

Rather than introducing special logic, it demonstrates the standard launch lifecycle exactly as every future token will experience it — mascot aside, the code doesn't know it's supposed to stay unbothered.

---

## 6.1 `PonsLaunchFactory` — Launch Orchestration

| Function | Role for $PEPONS |
|---|---|
| `launchToken(TokenParams, launchConfigId, dexId, salt)` | Deploys `$PEPONS`, initializes liquidity, creates the launch, and executes the entire launch process atomically |
| `predictTokenAddress(...)` | Demonstrates deterministic token deployment before launch |
| `graduationStatus(token)` | Shows how graduation is determined directly from on-chain liquidity data |
| `getLaunchedToken(token)` | Returns the permanent launch record for `$PEPONS` |
| `addDexConfig` / `addLaunchConfig` | Registers the launch configurations used throughout the documentation |
| `setLaunchEnabled` / `setWhitelistedLauncher` | Demonstrates protocol-level launch permissions |

---

## 6.2 `PonsLauncherToken` — Launch Behavior

| Function | Role for $PEPONS |
|---|---|
| `constructor(...)` | Creates the token supply, stores metadata, and initializes the launch state |
| `_update(from, to, value)` | Demonstrates launch protection, anti-sniping, and transfer restrictions — the unshakeable calm, functionally speaking |
| `liquidityPool()` | Resolves the canonical liquidity pool created during launch |
| `maxWalletLimit()` / `maxTxLimit()` | Demonstrates active wallet and transaction restrictions |
| `setInitialBuyRecipient(address)` | Allows the protocol's initial seed purchase during launch |
| `socials()` / `getTokenInfo()` | Returns metadata used throughout the documentation examples |
| `_isPairPool(candidate)` | Detects valid liquidity pools created by the protocol |

---

# 7. Why It Matters

`$PEPONS` serves multiple purposes simultaneously.

- **Protocol documentation** — the canonical example used throughout pons.family.
- **Developer education** — demonstrates the complete launch process from beginning to end.
- **Reference implementation** — every SDK, tutorial, guide, and integration can point to the same launch.
- **Regression testing** — future protocol versions can recreate `$PEPONS` to verify behavioral compatibility.
- **Infrastructure validation** — lockers, launch configurations, DEX integrations, and protocol upgrades can all be tested against a known reference launch.
- **Mascot duty** — every ecosystem needs a face, and this one comes with a built-in visual metaphor for "don't panic."

---

# 8. The Future of $PEPONS

To be completely clear:

**`$PEPONS` is a documentation and test token.**

It has **no holder utility**.

It is **not intended for speculation**.

Its purpose is to become the permanent educational reference — and mascot — for pons.family.

Every tutorial.

Every guide.

Every SDK example.

Every frontend.

Every explorer.

Every audit.

Every future launch.

Can reference one complete, canonical example, guarded by one perfectly unshakeable amphibian.

`$PEPONS`.

---

> *"Some mascots are cute so you'll trust them. This one just sits there so you don't have to worry."*

**Pepons by Pons ($PEPONS)**  
*The canonical launch walkthrough mascot of pons.family — test token, no value, no promises, zen calm included.*
