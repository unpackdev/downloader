// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPerlinNoise {
    function noise3d(int256, int256, int256) external view returns (int256);
}
