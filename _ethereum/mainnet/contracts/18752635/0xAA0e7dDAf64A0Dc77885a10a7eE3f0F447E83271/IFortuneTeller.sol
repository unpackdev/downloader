// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

interface IFortuneTeller {
    function revealFortune(uint256 fortune) external view returns (string[] memory);
    function revealCurse(uint256 curse) external view returns (string[] memory);
}
