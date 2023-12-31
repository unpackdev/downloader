// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./Types.sol";

interface IHouse {
    function getPlayerStats(address _account) external view returns (uint256, uint256, uint256, uint256, uint256);
}