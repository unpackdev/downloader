// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IXENCrypto {
    function globalRank() external view returns (uint256);
    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 EAA
        ) external view returns (uint256);
}