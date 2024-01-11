// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface SushiBar {
    // Enter the bar. Pay some SUSHIs. Earn some shares.
    function enter(uint256 _amount) external;

    // Leave the bar. Claim back your SUSHIs.
    function leave(uint256 _share) external;
}
