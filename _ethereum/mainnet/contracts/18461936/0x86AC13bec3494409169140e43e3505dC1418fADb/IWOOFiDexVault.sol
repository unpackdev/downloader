// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWOOFiDexVault {
    /* ----- Structs ----- */

    struct VaultDepositFE {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
    }

    /* ----- Events ----- */

    event AccountDepositTo(
        bytes32 indexed accountId,
        address indexed userAddress,
        uint64 indexed depositNonce,
        bytes32 tokenHash,
        uint128 tokenAmount
    );

    /* ----- Functions ----- */

    function depositTo(address receiver, VaultDepositFE calldata data) external payable;
}
