// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IVault.sol";

import "./IManagedPool.sol";

import "./IStakingLiquidityGauge.sol";
import "./IBalancerMinter.sol";

import "./WeightedPoolUserData.sol";
import "./StablePoolUserData.sol";

import "./IBalancerV2Vault.sol";
import "./IVaultGovernance.sol";
import "./IIntegrationVault.sol";

interface IBalancerV2VaultGovernance is IVaultGovernance {
    struct StrategyParams {
        IBalancerVault.BatchSwapStep[] swaps;
        IAsset[] assets;
        IBalancerVault.FundManagement funds;
        IAggregatorV3 rewardOracle;
        IAggregatorV3 underlyingOracle;
        uint256 slippageD;
    }

    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        address pool_,
        address balancerVault_,
        address stakingLiquidityGauge_,
        address balancerMinter_
    ) external returns (IBalancerV2Vault vault, uint256 nft);

    /// @notice Delayed Strategy Params
    /// @param nft VaultRegistry NFT of the vault
    function strategyParams(uint256 nft) external view returns (StrategyParams memory);

    /// @notice Delayed Strategy Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external;
}
