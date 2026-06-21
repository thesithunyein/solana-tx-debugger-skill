# Error Code Maps

> Comprehensive error-code references for Solana programs. Match hex/decimal codes to causes.

## How Anchor Errors Work

Anchor errors appear in logs as a decimal **Error Number** and/or a hex **custom program error**:
```
AnchorError caused by account: vault. Error Code: ConstraintSeeds. Error Number: 2006.
Program <id> failed: custom program error: 0x7d6
```

`2006` (decimal) == `0x7d6` (hex) — they're the same number. Anchor does **not** use a `0x1000` offset. Instead, error numbers fall into fixed ranges:

| Range (decimal) | Range (hex) | Category |
|---|---|---|
| 100–103 | 0x64–0x67 | Instruction errors |
| 1000–1002 | 0x3E8–0x3EA | IDL errors |
| 1500 | 0x5DC | Event errors |
| 2000–2042 | 0x7D0–0x7FA | **Constraint** errors (`#[account(...)]`) |
| 2500–2506 | 0x9C4–0x9CA | `require!` errors |
| 3000–3017 | 0xBB8–0xBC9 | **Account** errors |
| 4100–4102 | 0x1004–0x1006 | Miscellaneous |
| 5000 | 0x1388 | Deprecated |
| **6000+** | **0x1770+** | **User-defined `#[error_code]` errors** |

> **The single most useful fact:** your program's own custom errors start at **6000 (0x1770)**. So `0x1770` = your 1st custom error, `0x1771` = your 2nd, etc. `decimal = 6000 + index`.

### Constraint Errors (2000+) — violated `#[account(...)]` constraints

| Decimal | Hex | Error Name | Cause |
|---|---|---|---|
| 2000 | 0x7D0 | `ConstraintMut` | Account expected to be `mut` is not writable |
| 2001 | 0x7D1 | `ConstraintHasOne` | A `has_one` field doesn't match the target account |
| 2002 | 0x7D2 | `ConstraintSigner` | Account expected to sign did not sign |
| 2003 | 0x7D3 | `ConstraintRaw` | A raw `constraint = ...` expression evaluated false |
| 2004 | 0x7D4 | `ConstraintOwner` | Account owner doesn't match `owner = ...` |
| 2005 | 0x7D5 | `ConstraintRentExempt` | Account is not rent-exempt |
| 2006 | 0x7D6 | `ConstraintSeeds` | PDA derived from `seeds`/`bump` doesn't match the account |
| 2011 | 0x7DB | `ConstraintClose` | `close = ...` target invalid |
| 2012 | 0x7DC | `ConstraintAddress` | Account key doesn't match `address = ...` |
| 2013 | 0x7DD | `ConstraintZero` | Account was expected to be zeroed |
| 2014 | 0x7DE | `ConstraintTokenMint` | Token account mint doesn't match |
| 2015 | 0x7DF | `ConstraintTokenOwner` | Token account owner doesn't match |
| 2019 | 0x7E3 | `ConstraintSpace` | `space = ...` doesn't match required size |

### Account Errors (3000+) — account validation failures

| Decimal | Hex | Error Name | Cause |
|---|---|---|---|
| 3000 | 0xBB8 | `AccountDiscriminatorAlreadySet` | Tried to init an already-initialized account |
| 3001 | 0xBB9 | `AccountDiscriminatorNotFound` | Account has no 8-byte discriminator (uninitialized) |
| 3002 | 0xBBA | `AccountDiscriminatorMismatch` | Wrong account type (discriminator mismatch) |
| 3003 | 0xBBB | `AccountDidNotDeserialize` | Account data failed to deserialize |
| 3004 | 0xBBC | `AccountDidNotSerialize` | Account data failed to serialize |
| 3005 | 0xBBD | `AccountNotEnoughKeys` | Not enough accounts passed to the instruction |
| 3006 | 0xBBE | `AccountNotMutable` | Account expected to be mutable is not |
| 3007 | 0xBBF | `AccountOwnedByWrongProgram` | Account owned by an unexpected program |
| 3008 | 0xBC0 | `InvalidProgramId` | Program account has the wrong program ID |
| 3009 | 0xBC1 | `InvalidProgramExecutable` | Program account is not executable |
| 3010 | 0xBC2 | `AccountNotSigner` | The given account did not sign |
| 3011 | 0xBC3 | `AccountNotSystemOwned` | Account is not owned by the System program |
| 3012 | 0xBC4 | `AccountNotInitialized` | Account has not been initialized |
| 3013 | 0xBC5 | `AccountNotProgramData` | Account is not a ProgramData account |
| 3014 | 0xBC6 | `AccountNotAssociatedTokenAccount` | Account is not the expected ATA |

### `require!` Errors (2500+)

| Decimal | Hex | Error Name |
|---|---|---|
| 2500 | 0x9C4 | `RequireViolated` |
| 2501 | 0x9C5 | `RequireEqViolated` |
| 2502 | 0x9C6 | `RequireKeysEqViolated` |
| 2503 | 0x9C7 | `RequireNeqViolated` |
| 2505 | 0x9C9 | `RequireGtViolated` |

### Decoding a User-Defined Custom Error

If you see `custom program error: 0x1770` or higher from an Anchor program, it's a **user-defined** error:

```
index   = decimal_code - 6000
```

Look up `idl.errors[index]` (or the program's `#[error_code]` enum, in declaration order) to get the name and message. Example: `0x1772` = 6002 = the 3rd custom error.

## SPL Token Program Errors

Program ID: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`

| Code (hex) | Decimal | Error Name | Cause |
|---|---|---|---|
| 0x0 | 0 | `NotRentExempt` | Lamports below rent-exempt threshold |
| 0x1 | 1 | `InsufficientFunds` | Not enough tokens for the transfer/burn |
| 0x2 | 2 | `InvalidMint` | Mint account is invalid |
| 0x3 | 3 | `MintMismatch` | Token account's mint doesn't match |
| 0x4 | 4 | `OwnerMismatch` | Signer is not the owner/delegate |
| 0x5 | 5 | `FixedSupply` | Mint has a fixed supply, can't mint more |
| 0x6 | 6 | `AlreadyInUse` | Account is already in use/initialized |
| 0x7 | 7 | `InvalidNumberOfProvidedSigners` | Wrong number of multisig signers provided |
| 0x8 | 8 | `InvalidNumberOfRequiredSigners` | Multisig required-signers out of range |
| 0x9 | 9 | `UninitializedState` | Operation on an uninitialized account |
| 0xa | 10 | `NativeNotSupported` | Instruction not supported for native SOL |
| 0xb | 11 | `NonNativeHasBalance` | Can't close a non-native account with balance |
| 0xc | 12 | `InvalidInstruction` | Instruction data is malformed |
| 0xd | 13 | `InvalidState` | Account is in an invalid state |
| 0xe | 14 | `Overflow` | Arithmetic overflow |
| 0xf | 15 | `AuthorityTypeNotSupported` | Authority type not valid for this mint |
| 0x10 | 16 | `MintCannotFreeze` | Mint has no freeze authority configured |
| 0x11 | 17 | `AccountFrozen` | Token account is frozen |
| 0x12 | 18 | `MintDecimalsMismatch` | Decimals in `*_checked` call don't match mint |
| 0x13 | 19 | `NonNativeNotSupported` | Instruction not supported for non-native token |

## Token-2022 Program Errors

Program ID: `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`

Token-2022 **shares the same base error codes (0x0–0x13) as SPL Token above** (e.g., `AccountFrozen` is `0x11`/17, `InsufficientFunds` is `0x1`). On top of those it adds extension-specific errors, which start higher in the enum:

| Decimal | Error Name | Cause |
|---|---|---|
| — | `ExtensionTypeMismatch` | Extension type doesn't match the account |
| — | `ExtensionAlreadyInitialized` | Extension already initialized on this account |
| — | `MintHasSupplyNonZero` | Operation requires zero supply |
| — | `InvalidMintForExtension` | Extension not compatible with this mint |
| — | `TransferFeeExceedsMaximum` | Computed transfer fee exceeds the maximum |

> Because extension error indices vary by Token-2022 version, always confirm the exact code against `@solana/spl-token` (`TokenError` / extension error enums) for the version in use. The reliable signal is the **program ID** in the log: if it's `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`, it's Token-2022.

### Token-2022 Transfer Fee Extension

When using transfer fees, the effective amount needed is:
```
needed = amount + (amount * fee_bps) / 10000
```

If you see `InsufficientFunds` (0x1) on a Token-2022 transfer with the transfer fee extension, check whether you're accounting for the fee.

## System Program Errors

Program ID: `11111111111111111111111111111111`

| Code (hex) | Decimal | Error Name | Cause |
|---|---|---|---|
| 0x0 | 0 | `AccountAlreadyInUse` | `createAccount` target already exists (e.g., ATA/account already created) |
| 0x1 | 1 | `ResultWithNegativeLamports` | Transfer would leave the source with negative lamports (insufficient SOL) |
| 0x2 | 2 | `InvalidProgramId` | Assigned program ID is invalid |
| 0x3 | 3 | `InvalidAccountDataLength` | Requested account data length is invalid |
| 0x4 | 4 | `MaxSeedLengthExceeded` | A PDA seed exceeds 32 bytes |
| 0x5 | 5 | `AddressWithSeedMismatch` | `createAccountWithSeed` derived address doesn't match |
| 0x6 | 6 | `NonceNoRecentBlockhashes` | Durable nonce: no recent blockhashes available |
| 0x7 | 7 | `NonceBlockhashNotExpired` | Durable nonce: stored blockhash hasn't advanced |
| 0x8 | 8 | `NonceUnexpectedBlockhashValue` | Durable nonce: blockhash value mismatch |

> Note: “lamports in ≠ lamports out” is **not** a System program error code — the runtime rejects unbalanced instructions with a `TransactionError` (e.g., `InstructionError: UnbalancedInstruction`), not a System `custom program error`.

## Associated Token Account (ATA) Errors

Program ID: `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL`

| Code (hex) | Decimal | Error Name | Cause |
|---|---|---|---|
| 0x0 | 0 | `AccountAlreadyInitialized` | ATA already exists |
| 0x1 | 1 | `AssociatedAccountMismatch` | Wrong ATA for the mint/owner pair |
| 0x2 | 2 | `InvalidAssociatedTokenAccount` | Account is not a valid ATA |

## Memo Program Errors

Program ID: `MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr`

The Memo program doesn't return error codes — it only fails if the account is not writable or the instruction data is empty.

## How to Decode Any Custom Error

1. **Identify the failing program** from the log line `Program <id> failed: custom program error: 0x..`.
2. **Match the program ID** to a known program (SPL Token, Token-2022, System, ATA) and use the tables above with the raw code.
3. **If it's an Anchor program** (logs show `AnchorError` / `Error Number:`), convert the hex to decimal and map it by range: 2000s = constraint, 3000s = account, **6000+ = the program's own `#[error_code]`**.
4. For a user-defined error, look up `idl.errors[decimal - 6000]` or the `#[error_code]` enum in declaration order.

```typescript
function decodeAnchorError(
  hexCode: string,
  idlErrors: Record<number, string> = {},
): string {
  const code = parseInt(hexCode, 16); // e.g. "7d6" -> 2006
  if (code >= 6000) {
    const index = code - 6000;
    return idlErrors[index] ?? `User-defined #[error_code] #${index} (code ${code})`;
  }
  if (code >= 3000) return `Anchor account error ${code}`;
  if (code >= 2500) return `Anchor require! error ${code}`;
  if (code >= 2000) return `Anchor constraint error ${code}`;
  if (code >= 100 && code <= 103) return `Anchor instruction error ${code}`;
  return `Non-Anchor program error: 0x${hexCode} (decimal ${code})`;
}
```
