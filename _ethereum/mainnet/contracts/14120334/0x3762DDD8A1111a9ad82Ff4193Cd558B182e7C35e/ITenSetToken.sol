// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ITenSetToken {
    function tokenFromReflection(address ad, uint256 rAmount) external view returns (uint256);
}