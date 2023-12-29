// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct BasicMintConfiguration {
    /// @notice Purchase cost per token.
    uint256 price;
    /// @notice UNIX timestamp of mint start.
    uint64 mintStart;
    /// @notice UNIX timestamp of mint end, or zero if open-ended.
    uint64 mintEnd;
    /// @notice Maximum token purchase limit per wallet, or zero if no limit.
    uint32 maxPerWallet;
    /// @notice Maximum tokens mintable per transaction, or zero if no limit.
    uint32 maxPerTransaction;
    /// @notice Maximum tokens mintable by this module, or zero if no limit.
    uint32 maxForModule;
    /// @notice Maximum tokens that can be minted in total, or zero if no max.
    uint32 maxSupply;
}
