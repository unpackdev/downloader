// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IParaSwapAugustusRegistry {
    function isValidAugustus(address augustus) external view returns (bool);
}
