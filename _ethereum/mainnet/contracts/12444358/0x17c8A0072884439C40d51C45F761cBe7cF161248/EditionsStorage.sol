// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EditionsStorage {
    uint256 internal _safeMintBatchForArtistsAndTransferFlag;
    uint256 public currentId;

    // messages already minted
    mapping(bytes32 => bool) internal alreadyMinted;
}
