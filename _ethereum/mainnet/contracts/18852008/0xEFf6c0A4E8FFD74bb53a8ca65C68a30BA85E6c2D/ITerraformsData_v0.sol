// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITerraformsData_v0 {
    function characterSet(
        uint256,
        uint256
    ) external view returns (string[9] memory, uint256, uint256, uint256);

    function levelAndTile(
        uint256,
        uint256
    ) external view returns (uint256, uint256);

    function levelDimensions(uint256) external view returns (uint256);

    function resourceLevel(uint256, uint256) external view returns (uint256);

    function resourceName() external view returns (string memory);

    function tokenElevation(
        uint256,
        uint256,
        uint256
    ) external view returns (int256);

    function tokenZone(
        uint256,
        uint256
    ) external view returns (string[10] memory, string memory);

    function xOrigin(uint256, uint256, uint256) external view returns (int256);

    function yOrigin(uint256, uint256, uint256) external view returns (int256);
}
