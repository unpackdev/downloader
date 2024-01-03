// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

interface IFortuneCard {

    function revealFortuneCard(bool legendary) external view returns (string[] memory);

    function revealCursedCard(bool legendary) external view returns (string[] memory);
}
