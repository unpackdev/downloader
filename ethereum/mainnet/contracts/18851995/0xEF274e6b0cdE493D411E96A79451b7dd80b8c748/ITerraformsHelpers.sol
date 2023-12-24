// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Types.sol";

interface ITerraformsHelpers {
    function addressToENS(address) external view returns (string memory);

    function addressToString(address) external view returns (string memory);

    function calculateSeed(uint, uint) external pure returns (uint);

    function getActivation(uint256, uint256) external pure returns (Activation);

    function resourceDirection() external view returns (int256 result);

    function reverseUint(uint256) external view returns (uint256);

    function structureDecay(uint256) external view returns (uint256);

    function zOrigin(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external view returns (int256);

    function zOscillation(
        uint256 level,
        uint256 decay,
        uint256 timestamp
    ) external view returns (int256 result);
}
