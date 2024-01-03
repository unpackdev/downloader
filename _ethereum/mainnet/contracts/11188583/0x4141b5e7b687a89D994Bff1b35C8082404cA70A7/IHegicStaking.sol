// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IHegicStaking {
    function buy(uint256) external;

    function sell(uint256 amount) external;

    function profitOf(address) external view returns (uint256);

    function claimProfit() external returns (uint256);

    function lastBoughtTimestamp(address) external view returns (uint256);
}
