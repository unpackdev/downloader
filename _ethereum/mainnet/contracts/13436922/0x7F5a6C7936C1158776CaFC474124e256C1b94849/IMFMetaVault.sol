// contracts/IMFMetaVault.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMFMetaVault {
    function getMetadataByHash(
        uint _id, bytes9 packedHash
    )
        external
        view
        returns (string memory);
}