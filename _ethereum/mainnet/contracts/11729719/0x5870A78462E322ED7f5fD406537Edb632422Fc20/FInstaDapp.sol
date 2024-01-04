// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IInstaDapp.sol";
import "./CInstaDapp.sol";

function _setUint(uint256 setId, uint256 val) {
    if (setId != 0) MemoryInterface(INSTA_MEMORY).setUint(setId, val);
}

function _getUint(uint256 getId, uint256 val) returns (uint256 returnVal) {
    returnVal = getId == 0 ? val : MemoryInterface(INSTA_MEMORY).getUint(getId);
}
