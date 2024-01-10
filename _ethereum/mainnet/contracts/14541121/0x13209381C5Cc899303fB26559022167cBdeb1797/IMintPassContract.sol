// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintPass  {
    function isMintPassSalesActive() external returns (bool);
    function expend(uint256[] memory tokenIds,  uint256 totalAmountSent) external;
}