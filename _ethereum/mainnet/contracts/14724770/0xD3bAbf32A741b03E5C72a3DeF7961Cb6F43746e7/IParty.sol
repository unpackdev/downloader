// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IParty {
    function getDamage(address user) external view returns (uint32);

    function getUserHero(address user) external view returns (uint256);
}
