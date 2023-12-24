// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRDGXTokenSale {
    function getSalePeriod(bool _privatePhase) external view returns (uint256, uint256);
}
