// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseSFTConcrete {
    function isSlotValid(uint256 slot_) external view returns (bool);
} 