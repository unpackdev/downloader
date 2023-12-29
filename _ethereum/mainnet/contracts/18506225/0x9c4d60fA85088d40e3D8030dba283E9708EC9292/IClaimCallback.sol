// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IClaimCallback {
    function claimCallback(address claimant, address receiver, uint256 amount) external returns (bool success);
}

