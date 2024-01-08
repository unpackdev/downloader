// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IStrategyBase.sol";

interface IStrategy is IStrategyBase {
    function investedBalance() external view returns (uint256);

    function invest() external;

    function withdraw(uint256 amount) external returns (uint256);

    function withdrawAll() external;
}
