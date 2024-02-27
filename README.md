# Ethereum Smart Contracts Downloader and Storage Manager

## UNDER EARLY DEVELOPMENT

Currently, nothing works as expected. Going to remove this notice once state of the project changes.


## Overview
The Ethereum Smart Contracts Downloader and Storage Manager is a high-performance tool tailored for Ethereum smart contracts. Built with [Golang](https://go.dev/) and [BadgerDB](https://github.com/dgraph-io/badger), this application not only ensures efficient and dependable downloading of smart contracts but also provides robust features for pausing and resuming downloads. It facilitates seamless storage of contracts in a local database, simplifying access and retrieval.

Key capabilities include easy retrieval of contract metadata and source code, especially for contracts verified on [Etherscan](https://etherscan.io/). This makes it an indispensable tool for developers working with Ethereum smart contracts.

This project is inspired from [Smart Contract Sanctuary](https://github.com/tintinweb/smart-contract-sanctuary).
For now it will be focused only on mainnet contracts. Ethereum is the first one, Binance Smart Chain and Polygon will be added later including others.

## WARNING

- **Otterscan RPC-JSON api is required.** We use [Erigon](https://github.com/ledgerwatch/erigon).
- This tool is still in development and is not yet ready for production use.
- This repository is large. It contains gigabytes of data and will take a significant amount of time to clone. Please be mindful of this if you choose to download it.
- Due to licensing issues, I am not going to provide information that stricly breaks licenses. Instead, I am going to provide you the tools to extract information yourself if you have access to the 3rd party sources, utilising their respective API keys.

## Contract Processing Important Notes

- I am trying to keep as low as possible usage of third party services such as [Etherscan](https://etherscan.io/). Instead, focusing on [Smart Contract Sanctuary](https://github.com/tintinweb/smart-contract-sanctuary), [Sourcify.dev](https://sourcify.dev/) and direct access to the [IPFS](https://github.com/ipfs/kubo) network.
- With help of [SolGo](https://github.com/unpackdev/solgo) I am able to, if code is provided extract licenses and many other information from the source code itself.
- From the IPFS and deployed bytecode I am able to extract information such as if it's optimized or not, which compiler version, and so forth.


## Features
- **Efficient Contract Downloading:** Streamlined process for downloading Ethereum smart contracts.
- **Download Resumption:** Capability to pause and resume downloads, ensuring progress isn't lost.
- **Local Storage Management:** Stores contracts in BadgerDB for quick access and efficient retrieval.
- **Contract Metadata Access:** Easy access to essential contract metadata.
- **Bytecode Retrieval:** Simplifies the process of obtaining contract bytecode.
- **Source Code Access:** Provides easy access to the source code of verified contracts on Etherscan.
- **High-Performance Backend:** Built with Golang, known for its efficiency and speed.


## Demo and Examples

To be defined here. Will be a link with graphql playground, limited to 1req/s including examples in its own directory of
how to consume this service. Additional note is that demo will go down and up as I work on it, served from my own datacenter. 
I am not promising any availability.

You can access demo at [Downloader](https://downloader.playground.unpack.dev) **NOT ONLINE**

## Notes

These notes will be moved into appropriate sections of the README as the project progresses.

- For the best performance, it is recommended to run this project on NVME storage. This is because the database is very large and requires fast read and write to the storage to perform well.
- The database is currently around 20GB in size. 

## LICENSE

I am offering this code, not related to contracts at no cost, under the Apache License 2.0. For more details about this license, please refer to the [LICENSE](LICENSE) file included in this repository.

**Please note:** The contracts themselves are subject to their respective licenses. These licenses can be found within the source code of each individual contract. It is imperative that you review and adhere to these licenses when using the contracts.

## Message to Etherscan

I extend my sincere gratitude to the Etherscan team for your invaluable contributions. After reviewing your licensing terms, I believe that my use of your services aligns with these terms. However, should there be any concerns or issues regarding my usage, I welcome your feedback and guidance. Please feel free to contact me at [info(at)unpack.dev](mailto:info@unpack.dev).
