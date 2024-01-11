// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDillGauge {
    function deposit(uint256) external;
    function depositFor(uint256, address) external;
    function depositAll() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
    function exit() external;
    function getReward() external;
    function balanceOf(address) external view returns (uint256);
}