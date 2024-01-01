// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./VaultTypes.sol";

interface IStrategy {
    /// Roles
    function grantRoles(address user, uint256 roles) external payable;

    function revokeRoles(address user, uint256 roles) external payable;

    function renounceRoles(uint256 roles) external payable;

    function harvest(uint256 minExpectedBalance, uint256 minOutputAfterInvestment) external;

    function setEmergencyExit(uint256 _emergencyExit) external;

    function setStrategist(address _newStrategist) external;

    function vault() external returns (address);

    function underlyingAsset() external returns (address);

    function emergencyExit() external returns (uint256);

    function withdraw(uint256 amountNeeded) external returns (uint256);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function strategist() external view returns (address);

    function strategyName() external view returns (bytes32);

    function isActive() external view returns (bool);

    /// View roles
    function hasAnyRole(address user, uint256 roles) external view returns (bool result);

    function hasAllRoles(address user, uint256 roles) external view returns (bool result);

    function rolesOf(address user) external view returns (uint256 roles);

    function rolesFromOrdinals(uint8[] memory ordinals) external pure returns (uint256 roles);

    function ordinalsFromRoles(uint256 roles) external pure returns (uint8[] memory ordinals);
}
