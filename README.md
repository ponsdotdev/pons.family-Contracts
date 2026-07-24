# Pons Launchpad Contracts

Smart contracts that power the ponsfamily.com token launchpad on Robinhood Chain.
 
**Deployed factory**
     
`0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB`
      
This repository is the Solidity source for that deployment: a CREATE2 factory that mints a fixed-supply ERC-20, seeds a one-sided Uniswap V3 position, locks the position NFT, and can run an optional developer buy in the same transaction. 
    
## Stack  
      
| Item | Value |
|------|-------| 
| Language | Solidity `^0.8.30` |
| Chain | Robinhood Chain (EVM L2) |
| Product | ponsfamily.com |
| Factory | `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB` |
| Access control | OpenZeppelin `Ownable2Step` |
| Safety | OpenZeppelin `ReentrancyGuard`, `SafeERC20` |

## Repository layout

```text
.
├── README.md
├── abi.json
├── contract-meta.json
└── contracts/
    ├── src/
    │   ├── PonsLaunchFactory.sol
    │   ├── PonsLauncherToken.sol
    │   ├── interfaces/
    │   │   └── ILaunchpad.sol
    │   └── libraries/
    │       ├── PonsLiquidityMath.sol
    │       └── PonsTickMath.sol
    └── lib/
        └── openzeppelin-contracts/
            └── contracts/
                ├── access/
                │   ├── Ownable.sol
                │   └── Ownable2Step.sol
                ├── interfaces/
                │   ├── IERC1363.sol
                │   ├── IERC165.sol
                │   ├── IERC20.sol
                │   ├── IERC20Metadata.sol
                │   └── draft-IERC6093.sol
                ├── token/ERC20/
                │   ├── ERC20.sol
                │   ├── IERC20.sol
                │   ├── extensions/IERC20Metadata.sol
                │   └── utils/SafeERC20.sol
                └── utils/
                    ├── Context.sol
                    ├── Panic.sol
                    ├── ReentrancyGuard.sol
                    ├── StorageSlot.sol
                    ├── introspection/IERC165.sol
                    └── math/
                        ├── Math.sol
                        └── SafeCast.sol
```

## First-party contracts

### `contracts/src/PonsLaunchFactory.sol`

Core launchpad entrypoint used by pons.family.

- Owner-managed DEX profiles (Uniswap V3 factory, NFT position manager, swap router, fee tier, tick spacing)
- Owner-managed launch presets (pair asset, supply, anti-snipe windows, graduation threshold, initial tick)
- `launchToken(...)` — deploy token via CREATE2, initialize pool, mint one-sided liquidity, lock the NFT through the configured locker, optionally swap leftover native value into the new token
- `predictTokenAddress(...)` — deterministic address preview for UI / integrators
- `graduationStatus(...)` — reads locked position principal against the stored threshold

Live address: `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB`

#### Fixed token address suffix (`…bbbb`)

Every token deployed by `launchToken` ends with hex `bbbb`.


### `contracts/src/PonsLauncherToken.sol`

Fixed-supply ERC-20 spawned by the factory for each launch.

- Entire supply minted to the factory, then deposited as V3 liquidity
- On-chain metadata: logo, description, socials
- Early-window buy limits against the canonical pool (same-block buy block, max wallet, cumulative max tx)
- Narrow factory-controlled exemption so the atomic launch buy can settle cleanly

### `contracts/src/interfaces/ILaunchpad.sol`

Slim interfaces the factory and token depend on:

- Uniswap V3 factory / pool / position manager shapes
- SwapRouter02 and classic V3 router param structs
- `IPonsLaunchFactory.LaunchedToken` record
- `IPonsLaunchLocker` hooks used after the position NFT is transferred out of the factory

### `contracts/src/libraries/PonsLiquidityMath.sol`

Pure math that converts concentrated liquidity into token0 / token1 principal. Used by graduation checks so donated inventory hanging in the pool does not fake progress.

### `contracts/src/libraries/PonsTickMath.sol`

Tick → `sqrtPriceX96` helper used when initializing the launch pool so prices line up with Uniswap V3 expectations.

## Vendor dependencies (`contracts/lib/openzeppelin-contracts`)

OpenZeppelin Contracts vendored for this build (same compiler settings as the live factory).

| File | Role in this project |
|------|----------------------|
| `access/Ownable.sol` | Base ownership primitives |
| `access/Ownable2Step.sol` | Two-step owner transfer on the factory |
| `token/ERC20/ERC20.sol` | ERC-20 implementation inherited by `PonsLauncherToken` |
| `token/ERC20/IERC20.sol` | ERC-20 interface |
| `token/ERC20/extensions/IERC20Metadata.sol` | name / symbol / decimals interface |
| `token/ERC20/utils/SafeERC20.sol` | Safe approvals & transfers in the factory |
| `utils/Context.sol` | `msg.sender` abstraction used by Ownable / ERC20 |
| `utils/ReentrancyGuard.sol` | Guards `launchToken` |
| `utils/Panic.sol` | Panic helpers used by Math |
| `utils/StorageSlot.sol` | Low-level storage helpers |
| `utils/math/Math.sol` | `mulDiv` for liquidity valuation |
| `utils/math/SafeCast.sol` | Safe integer casting helpers |
| `utils/introspection/IERC165.sol` | ERC-165 interface |
| `interfaces/IERC20.sol` | Interface re-export path |
| `interfaces/IERC20Metadata.sol` | Interface re-export path |
| `interfaces/IERC165.sol` | Interface re-export path |
| `interfaces/IERC1363.sol` | ERC-1363 interface referenced by SafeERC20 |
| `interfaces/draft-IERC6093.sol` | Custom ERC-20 error definitions |

## Artifact files

### `abi.json`

ABI for `PonsLaunchFactory` at `0xA5aAb3F0c6EeadF30Ef1D3Eb997108E976351feB`. Suitable for ethers / viem / cast bindings used by the pons.family frontend and tooling.

### `contract-meta.json`

Build and deployment notes for the live factory (compiler version, optimizer settings, EVM target, file list).

## Design notes

1. **One transaction launch** — token, pool, LP lock, and optional seed buy share a single `launchToken` call so frontend wallets only sign once.
2. **Fixed `…dddd` addresses** — every launched token address ends in `dddd`.
3. **One-sided V3 liquidity** — full supply sits on one side of the range; paired asset depth grows as traders buy in.
4. **Temporary buy pressure limits** — restriction window lives on the token; plain ERC-20 behavior resumes afterward.
5. **Graduation without fake depth** — status is derived from locked position principal, not arbitrary wallet balances.

## License

- First-party Pons contracts: MIT (see SPDX headers)
- `PonsTickMath.sol`: GPL-2.0-or-later (Uniswap V3 tick math lineage)
- OpenZeppelin sources: MIT (upstream)
