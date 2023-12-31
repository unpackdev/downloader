// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IIntegrationVault.sol";

import "./IAggregatorV3.sol";
import "./IVault.sol";

interface IBalancerV2Vault is IIntegrationVault {
    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        address pool_,
        address balancerVault_,
        address stakingLiquidityGauge_,
        address balancerMinter_
    ) external;

    function getPriceToUSDX96(IAggregatorV3 oracle, IAsset token) external view returns (uint256 priceX96);

    function claimRewards() external;

    function claimBalancerRewardToken() external returns (uint256 amount);
}
