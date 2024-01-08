//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

interface IPair {
    function addLiquid(uint amount0, uint amount1) external;
    function getReserves() external view returns (uint, uint, uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}