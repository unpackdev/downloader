// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

interface IFortuneTeller {

    function revealFortune(uint256 fortune) external pure returns (string[] memory);

    function fortunateTraits(string[] memory revealed) external pure returns (string memory);

    function revealCurse(uint256 curse) external pure returns (string[] memory);

    function cursedTraits(string[] memory revealed) external pure returns (string memory);
}
