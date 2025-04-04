# Forever Library NFT Minting Contract

Forever Library NFT Minting Contract is a robust, secure, and immutable ERC-721 NFT contract built with Solidity and OpenZeppelin.

## Features

- **ERC-721 Compliant**: Built on the widely-adopted ERC-721 standard for NFTs
- **Immutable Contract**: No owner privileges, ensuring fair and decentralized operation
- **Open Minting**: Anyone can mint NFTs without restrictions
- **Metadata Security**:
  - 24-hour window to update metadata after minting
  - After 24 hours, metadata becomes permanently locked
- **External Renderer Support**: Compatible with generative art systems through an external renderer interface
- **Non-Upgradeable**: Contract logic is fixed at deployment, providing certainty for collectors
- **Reentrancy Protection**: Implements OpenZeppelin's ReentrancyGuard for enhanced security

## Smart Contract Overview

The Forever Library contract provides a secure and transparent way to mint NFTs with the following guarantees:

1. **Open Minting**: Any address can mint NFTs by providing a token URI
2. **Creator Control**: Only the creator of a token can modify its metadata within the 24-hour window
3. **Permanent Storage**: After 24 hours, token metadata becomes immutable
4. **External Rendering**: Optional support for external renderers to generate dynamic content
5. **Security First**: Implements best practices for smart contract security

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
