// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

contract PresaleFunctions {

    // ---
    // Properties
    // ---

    bool public presaleMint;
    bool public presaleActive;
    bool public presaleDifferentMintPrice;
    uint256 public presaleMintPriceInWei;

    // ---
    // Mappings
    // ---

    mapping(address => bool) public isPresaleAddress;
}