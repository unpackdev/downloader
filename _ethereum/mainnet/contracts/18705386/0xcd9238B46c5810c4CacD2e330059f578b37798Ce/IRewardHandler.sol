// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

interface IRewardHandler {

    event TokenFee(address indexed token, uint256 value);

    event NativeFee(uint256 value);

    function logTokenFee(address token, uint256 fee) external returns (bool);

    function logNativeFee(uint256 fee) external returns (bool);
}