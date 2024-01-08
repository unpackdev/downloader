// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIDOTier {
    function getTier(address user) external view returns (uint256);

    function getMultiplier(address user) external view returns (uint256);

    function getTotalMultiplier() external view returns (uint256);

    function getMultiplierAtIndex(uint256) external view returns (uint256);

    function getMultiplierAtTierId(uint256 tierId) external view returns (uint256);

    function getTierId(address user) external view returns (uint256);
}
