# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Per-circuit commands (always use `--package <name>`)
```bash
nargo check --package <name>        # type-check a circuit
nargo compile --package <name>      # compile → target/<name>.json
nargo execute --package <name>      # run witness generation → target/<name>.gz
nargo test --package <name>         # run tests (suppress output by default)
nargo test --package <name> --show-output   # show println() output
```

### Workspace-wide
```bash
nargo execute --workspace           # execute all circuits
```

### Proving (Barretenberg backend)
```bash
bb write_vk -b ./target/<name>.json -o ./target          # generate verification key
bb prove -b ./target/<name>.json -w ./target/<name>.gz -o ./target   # generate proof
```

Note: `-p` in `nargo execute` is `--prover-name` (the input toml filename), NOT `--package`. Always use the long form `--package`.

## Architecture

This is a **Nargo workspace** of Noir ZK circuits. The root `Nargo.toml` declares `[workspace]` with members; each circuit under `circuits/` has its own `[package]` `Nargo.toml`, `Prover.toml` (witness inputs), and `src/main.nr`. All compiled artifacts land in the shared root `target/` directory, namespaced by package name.

### Circuits

**`circuits/default`** — minimal inequality check (`x != y`). No dependencies. Learning scaffold.

**`circuits/panagram`** — magic word guessing game using Poseidon2. Takes `raw_secret_word` as private input, two public hashes (`secret_word_hash`, `user_answer_hash`), returns `bool`. The circuit hashes the secret word internally and compares against both public commitments — `secret_word_hash` binds the prover to a pre-committed word, the return value indicates whether the guess matched.

**`circuits/merkle_allowlist`** — Merkle membership proof for an allowlist. Proves a wallet address belongs to a Merkle tree without revealing which address. Uses `bn254::hash_1` to hash `raw_wallet` into a leaf, then `MerkleTree::membership` to verify the sibling path against the public root. Fixed depth 10 (supports up to 1024 addresses).

### Key constraints

**Hash function alignment**: the JS frontend and Noir circuit must use the same Poseidon implementation.
- `poseidon-lite` (`poseidon1`, `poseidon2`) in JS ↔ `dep::poseidon::poseidon::bn254` (`hash_1`, `hash_2`) in Noir
- These are the original BN254 Poseidon (iden3/circomlib spec), NOT `std::hash::poseidon2` (a different variant)
- The number suffix means input count: `poseidon1`/`hash_1` = 1 input (leaf hashing), `poseidon2`/`hash_2` = 2 inputs (combining tree nodes)
- `std::hash::poseidon::bn254` does NOT exist in Noir stdlib (v1.0.0-beta.21+) — must use the external `poseidon` crate

**Merkle tree**: use `IMT` (fixed-depth) from `@zk-kit/imt` in JS, not `LeanIMT`. LeanIMT changes depth as leaves are added, requiring circuit recompilation. IMT with a fixed depth (e.g. 10) always produces exactly `depth` siblings, matching the fixed `[Field; N]` circuit parameter.
- `IMT` uses `createProof(index)` not `generateProof`
- Proof returns `proof.leafIndex` (use as `indexes` input) and `proof.siblings` (use as `hash_path`)
- IMT constructor: `new IMT((inputs) => poseidon2(inputs), MAX_DEPTH, 0n, 2)`

**Trait imports for `dep::trees`**: calling `MerkleTree::from` requires `MT_Creator` in scope; calling `tree.membership` requires `MembershipProver`. Both must be imported explicitly from `dep::trees::types`. Alternatively, implement the membership check manually (loop over `hash_path` with `bn254::hash_2`) to avoid trait imports entirely.

**Field size**: Noir's `Field` on BN254 is ~254 bits. Ethereum addresses (160 bits) and Poseidon outputs fit safely. keccak256 outputs (256 bits) do not — avoid keccak256 in circuits or as Merkle hash function.

**`Prover.toml` values**: all inputs are decimal strings. Ethereum addresses must be converted to `BigInt` decimal before passing (e.g. `BigInt("0xDE645...").toString()`).

### Dependencies (per circuit)
- `poseidon = { tag = "v0.1.1", git = "https://github.com/noir-lang/poseidon" }` — original Poseidon for BN254; import as `dep::poseidon::poseidon::bn254`
- `trees = { git = "https://github.com/privacy-scaling-explorations/zk-kit.noir", tag = "merkle-trees-v0.0.1", directory = "packages/merkle-trees" }` — `MerkleTree<T>` with `membership`, `MT_Creator` (for `from`), and `MembershipProver` traits; all three must be imported explicitly
