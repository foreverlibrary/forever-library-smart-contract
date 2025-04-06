# Forever Library Smart Contract

A fully immutable, non-upgradeable NFT contract with open minting and permanent metadata.

## Deployment to Sepolia

1. Install dependencies:

```bash
forge install
```

2. Set up environment variables:

- Copy `.env.example` to `.env`
- Fill in your private key, Sepolia RPC URL, and Etherscan API key

3. Build the contract:

```bash
forge build
```

4. Deploy to Sepolia:

```bash
forge script script/ForeverLibrary.s.sol:ForeverLibrary --rpc-url sepolia --broadcast --verify -vvvv
```

5. Verify the contract on Etherscan:

```bash
forge verify-contract --chain-id 11155111 --constructor-args $(cast abi-encode "constructor()" "") --watch <DEPLOYED_ADDRESS> src/ForeverLibrary.sol:ForeverLibrary
```

## Testing

Run the test suite:

```bash
forge test
```

## Features

- ERC-721 compliant
- Immutable contract (not ownable)
- Openly mintable by public
- Immutable metadata after 24 hours
- External renderer support for generative art
- 24-hour time lock before metadata is locked

## Smart Contract Overview

The Forever Library NFT Minting Contract provides a secure and transparent way to mint NFTs with the following guarantees:

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
