// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnhancer {
    function onEnhancement(uint256) external returns (bytes4);
}
