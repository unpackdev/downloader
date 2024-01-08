// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface CopMappingInterface {
    function getTokenAddress() external view returns (address);
    function getProtectionData(uint256 underlyingTokenId) external view returns (address, uint256, uint256, uint256, uint, uint);
    function getUnderlyingAsset(uint256 underlyingTokenId) external view returns (address);
    function getUnderlyingAmount(uint256 underlyingTokenId) external view returns (uint256);
    function getUnderlyingStrikePrice(uint256 underlyingTokenId) external view returns (uint);
    function getUnderlyingDeadline(uint256 underlyingTokenId) external view returns (uint);

}