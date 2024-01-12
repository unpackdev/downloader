// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClaimControl {
    function canClaimedForOneNFT(uint256 time) external view returns (uint256 amount);
}