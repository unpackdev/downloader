// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface PieRecipe {
    function toPie(address _pie, uint256 _poolAmount) external payable;

    function calcToPie(address _pie, uint256 _poolAmount)
        external
        view
        returns (uint256);
}
