# Error Code Maps

> Comprehensive error-code references for Solana programs. Match hex/decimal codes to causes.

## How Anchor Errors Work

Anchor errors appear in logs as:
```
Program returned error: "custom program error: 0x1006"
```

The hex value `0x1006` encodes:
- `0x1000` = Anchor error offset (always present for Anchor programs)
- `0x0006` = error index (6th variant in `#[error_code]`)

So `0x1006` → Anchor error #6.

For custom program errors **without** the `0x1000` offset (e.g., `0x1`), it's a raw BPF program error — see the SPL/System sections below.

### Anchor Built-in Errors (offset 0x1000, indices 0–255)

| Code (hex) | Index | Error Name | Cause |
|---|---|---|---|
| 0x1000 | 0 | `InstructionMissing` | No instruction data provided |
| 0x1001 | 1 | `InstructionFallbackNotFound` | Instruction not found in IDL |
| 0x1002 | 2 | `InstructionDidNotDeserialize` | Account data deserialization failed |
| 0x1003 | 3 | `InstructionDidNotSerialize` | Account data serialization failed |
| 0x1004 | 4 | `ImmutableAccount` | Account expected to be mutable is immutable |
| 0x1005 | 5 | `IncorrectProgramId` | Account owned by wrong program |
| 0x1006 | 6 | `AccountNotSigner` | Account should be a signer but isn't |
| 0x1007 | 7 | `AccountNotWritable` | Account should be writable but isn't |
| 0x1008 | 8 | `AccountNotAssociated` | Associated token account mismatch |
| 0x1009 | 9 | `InsufficientFunds` | Token account has insufficient balance |
| 0x100a | 10 | `AccountAlreadyInitialized` | Account is already initialized |
| 0x100b | 11 | `UninitializedAccount` | Account is not initialized |
| 0x100c | 12 | `NotAssociated` | Token account not associated with owner |
| 0x100d | 13 | `AmountExceedsActual` | Tried to withdraw more than available |
| 0x100e | 14 | `ConstraintSeeds` | PDA seeds don't match expected |
| 0x100f | 15 | `ConstraintZero` | Expected zero, got non-zero |
| 0x1010 | 16 | `ProgramIdPrefix` | Program ID constraint mismatch |
| 0x1011 | 17 | `AccountDiscriminatorAlreadySet` | Account discriminator already exists |
| 0x1012 | 18 | `AccountDiscriminatorNotFound` | Account discriminator doesn't match |
| 0x1013 | 19 | `AccountDiscriminatorMismatch` | Wrong account type for this instruction |
| 0x1014 | 20 | `DidNotDeserialize` | Account data didn't deserialize correctly |
| 0x1015 | 21 | `DidNotSerialize` | Account data didn't serialize correctly |
| 0x1016 | 22 | `InsufficientFundsForRent` | Account balance below rent-exempt minimum |
| 0x1017 | 23 | `InvalidAccountOwnership` | Account not owned by expected program |

### Custom Anchor Errors (offset 0x1000 + 256+)

When a program defines `#[error_code]` with custom errors, the index starts at 256 (0x100):

```
0x1100 = custom error #256 (first user-defined error)
0x1101 = custom error #257
```

To decode: `custom_index = hex_code - 0x1000`, then look up the program's `#[error_code]` enum.

## SPL Token Program Errors

Program ID: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`

| Code (hex) | Decimal | Error Name | Cause |
|---|---|---|---|
| 0x1 | 1 | `InsufficientFunds` | Not enough tokens for transfer |
| 0x2 | 2 | `AccountNotAssociated` | Source/dest not associated correctly |
| 0x3 | 3 | `OwnerMismatch` | Signer is not the account owner |
| 0x4 | 4 | `FixedSupply` | Supply is fixed, can't mint more |
| 0x5 | 5 | `MintMismatch` | Token account mint doesn't match expected |
| 0x6 | 6 | `NotInitialized` | Token account not initialized |
| 0x7 | 7 | `AmountExceedsSupply` | Burn amount exceeds supply |
| 0x8 | 8 | `InvalidInstruction` | Instruction data is malformed |
| 0x9 | 9 | `InvalidAccountOwner` | Account not owned by Token program |
| 0xa | 10 | `AccountAlreadyInitialized` | Account already initialized |
| 0xb | 11 | `UninitializedState` | Operation on uninitialized account |
| 0xc | 12 | `NotEnoughRent` | Account not rent-exempt |
| 0xd | 13 | `AuthorityTypeNotSupported` | Authority type not valid for this mint |
| 0xe | 14 | `InvalidAuthorityType` | Authority type doesn't match instruction |

## Token-2022 Program Errors

Program ID: `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`

Token-2022 shares the base SPL Token error codes above, plus extension-specific errors:

| Code (hex) | Decimal | Error Name | Cause |
|---|---|---|---|
| 0x12 | 18 | `ExtensionTypeMismatch` | Wrong extension for this account |
| 0x13 | 19 | `ExtensionAlreadyInitialized` | Extension already present |
| 0x14 | 20 | `MintCannotFreeze` | Mint doesn't have freeze authority configured |
| 0x15 | 21 | `MintHasAuthorityType` | Authority type already set |
| 0x16 | 22 | `AccountFrozen` | Account is frozen by freeze authority |
| 0x17 | 23 | `InvalidMintForExtension` | Extension not compatible with this mint |
| 0x18 | 24 | `InsufficientFundsForFee` | Transfer fee deduction leaves insufficient funds |
| 0x19 | 25 | `ConflictingExtensionTypes` | Two extensions conflict with each other |
| 0x1a | 26 | `ExtensionMismatch` | Extension data doesn't match expected |
| 0x1b | 27 | `InvalidExtensionAccount` | Account not valid for this extension |

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
| 0x0 | 0 | `AccountAlreadyInUse` | Account already has an owner |
| 0x1 | 1 | `ResultWithNegativeLamports` | Would result in negative balance |
| 0x2 | 2 | `InvalidProgramId` | Program ID doesn't match |
| 0x3 | 3 | `InvalidAccountDataLength` | Data length must be 0 for system accounts |
| 0x4 | 4 | `MaxSeedLengthExceeded` | PDA seed too long (max 32 bytes) |
| 0x5 | 5 | `AddressWitherMismatch` | PDA doesn't match derived address |
| 0x6 | 6 | `NonZeroAccountData` | Account data must be zero for create_account |
| 0x7 | 7 | `UnbalancedInstruction` | Lamports in ≠ lamports out |
| 0x8 | 8 | `IncorrectProgramId` | Account not owned by System program |
| 0x9 | 9 | `InvalidAccountData` | Account data is invalid |
| 0xa | 10 | `MaxAccountsDataAllocationsExceeded` | Too much data allocated |
| 0xb | 11 | `MaxAccountsExceeded` | Too many accounts in instruction |

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

1. Strip the `0x1000` offset if present → that's an Anchor error
2. If no offset, check if the program is SPL Token, Token-2022, System, or ATA → use the tables above
3. If it's a custom program, look up the program's `#[error_code]` enum in its source/IDL
4. If you have the Anchor IDL, the error names are in `idl.errors[]`

```typescript
function decodeAnchorError(hexCode: string, idlErrors: Record<number, string>): string {
  const code = parseInt(hexCode, 16);
  const anchorOffset = 0x1000;
  if (code >= anchorOffset) {
    const index = code - anchorOffset;
    return idlErrors[index] ?? `Unknown Anchor error #${index}`;
  }
  return `Non-Anchor custom error: 0x${hexCode}`;
}
```
