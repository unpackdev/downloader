// SPDX-FileCopyrightText: 2021 Tenderize <info@tenderize.me>

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";

interface ITenderizer {
    function deposit(uint256 _amount) external;
    function claimRewards() external;
    function node() external view returns (address);
    function totalStakedTokens() external view returns (uint256 totalStaked);
}