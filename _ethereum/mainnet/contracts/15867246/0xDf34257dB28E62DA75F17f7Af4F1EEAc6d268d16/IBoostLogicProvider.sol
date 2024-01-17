// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IBoostLogicProvider {
    function hasMaxBoostLevel(address account) external view returns (bool);
}
