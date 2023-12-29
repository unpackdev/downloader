// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITerraformsData {
    function tokenHeightmapIndices(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory
    ) external view returns (uint256[32][32] memory);
}
