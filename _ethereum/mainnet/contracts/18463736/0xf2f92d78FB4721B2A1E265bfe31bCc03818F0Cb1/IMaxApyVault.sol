// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./VaultTypes.sol";

/**
 * @notice MaxApyVault contains the main interface for MaxApy Vaults
 */
interface IMaxApyVault {
    /// User-facing vault functions
    function deposit(uint256 amount, address recipient) external returns (uint256);

    function withdraw(uint256 shares, address recipient, uint256 maxLoss) external returns (uint256);

    function report(uint128 gain, uint128 loss, uint128 debtPayment) external returns (uint256);

    /// ERC20 Token functions
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function underlyingAsset() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    /// Ownership
    function transferOwnership(address newOwner) external payable;

    function renounceOwnership() external payable;

    function requestOwnershipHandover() external payable;

    function cancelOwnershipHandover() external payable;

    function completeOwnershipHandover(address pendingOwner) external payable;

    /// View ownership
    function ownershipHandoverExpiresAt(address pendingOwner) external view returns (uint256);

    function ownershipHandoverValidFor() external view returns (uint64);

    function owner() external view returns (address result);

    /// Roles
    function grantRoles(address user, uint256 roles) external payable;

    function revokeRoles(address user, uint256 roles) external payable;

    function renounceRoles(uint256 roles) external payable;

    /// View roles
    function ADMIN_ROLE() external returns (uint256);

    function EMERGENCY_ADMIN_ROLE() external returns (uint256);

    function KEEPER_ROLE() external returns (uint256);

    function STRATEGY_ROLE() external returns (uint256);

    function hasAnyRole(address user, uint256 roles) external view returns (bool result);

    function hasAllRoles(address user, uint256 roles) external view returns (bool result);

    function rolesOf(address user) external view returns (uint256 roles);

    function rolesFromOrdinals(uint8[] memory ordinals) external pure returns (uint256 roles);

    function ordinalsFromRoles(uint256 roles) external pure returns (uint8[] memory ordinals);

    /// Vault configuration
    function debtRatio() external returns (uint256);

    function totalDebt() external returns (uint256);

    function totalIdle() external returns (uint256);

    function strategies(address strategy) external returns (StrategyData memory);

    function withdrawalQueue(uint256 index) external returns (address);

    function emergencyShutdown() external returns (bool);

    /// Vault management
    function setEmergencyShutdown(bool _emergencyShutdown) external;

    function addStrategy(
        address newStrategy,
        uint256 strategyDebtRatio,
        uint256 strategyMaxDebtPerHarvest,
        uint256 strategyMinDebtPerHarvest,
        uint256 strategyPerformanceFee
    ) external;

    function revokeStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function updateStrategyData(
        address strategy,
        uint256 newDebtRatio,
        uint256 newMaxDebtPerHarvest,
        uint256 newMinDebtPerHarvest,
        uint256 newPerformanceFee
    ) external;

    function setWithdrawalQueue(address[20] calldata queue) external;

    function setPerformanceFee(uint256 _performanceFee) external;

    function setManagementFee(uint256 _managementFee) external;

    function setLockedProfitDegradation(uint256 _lockedProfitDegradation) external;

    function setDepositLimit(uint256 _depositLimit) external;

    function setTreasury(address _treasury) external;

    /// Vault view functions
    function performanceFee() external returns (uint256);

    function managementFee() external returns (uint256);

    function lockedProfitDegradation() external view returns (uint256);

    function depositLimit() external returns (uint256);

    function MAXIMUM_STRATEGIES() external returns (uint256);

    function DEGRADATION_COEFFICIENT() external view returns (uint256);

    function shareValue(uint256 shares) external view returns (uint256);

    function sharesForAmount(uint256 amount) external view returns (uint256 shares);

    function debtOutstanding(address strategy) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function lockedProfit() external view returns (uint256);

    function treasury() external view returns (address);
}
