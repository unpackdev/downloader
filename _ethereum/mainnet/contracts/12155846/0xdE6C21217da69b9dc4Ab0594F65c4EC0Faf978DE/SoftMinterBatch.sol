// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface CanAddHash {
    function addHash(address to, bytes32 dataHash) external;
}

contract SoftMinterBatch is Ownable {
    CanAddHash private _softMinter;

    constructor(CanAddHash softMinter) public {
        _softMinter = softMinter;
    }

    function addHashes(address[] memory to, bytes32[] memory dataHash) public onlyOwner {
        require(to.length == dataHash.length, "Inputs do not have the same size");
        for (uint i = 0; i < to.length; i++) {
            _softMinter.addHash(to[i], dataHash[i]);
        }
    }
}