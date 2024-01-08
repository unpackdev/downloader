// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ITellor
 */
interface ITellor {
    function balanceOf(address _user) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}

