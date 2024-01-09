pragma solidity 0.8.11;
// SPDX-License-Identifier: CC0-1.0

contract DummyNFT {
    constructor() {}

    function isApprovedForAll(address, address) public view returns (bool) {
        return true;
    }
}