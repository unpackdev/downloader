// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IToken {
    function getTotalFee() external returns (uint256);
    function getOwnedBalance(address account) external view returns (uint);
}