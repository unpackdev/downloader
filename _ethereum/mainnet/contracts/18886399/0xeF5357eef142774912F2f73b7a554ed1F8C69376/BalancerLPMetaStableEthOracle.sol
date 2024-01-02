// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.

pragma solidity 0.8.17;

import "./Errors.sol";
import "./BalancerUtilities.sol";
import "./ISystemRegistry.sol";
import "./IPriceOracle.sol";
import "./IERC20.sol";
import "./IVault.sol";
import "./IBalancerMetaStablePool.sol";
import "./IRateProvider.sol";
import "./BalancerBaseOracle.sol";

/// @title Price oracle for Balancer Meta Stable pools
/// @dev getPriceEth is not a view fn to support reentrancy checks. Dont actually change state.
contract BalancerLPMetaStableEthOracle is BalancerBaseOracle, IPriceOracle {
    error InvalidTokenCount(address token, uint256 length);
    error InvalidPool(address token);

    constructor(
        ISystemRegistry _systemRegistry,
        IVault _balancerVault
    ) BalancerBaseOracle(_systemRegistry, _balancerVault) { }

    // slither-disable-start missing-zero-check
    // slither-disable-start low-level-calls
    /// @inheritdoc IPriceOracle
    function getPriceInEth(address token) external returns (uint256 price) {
        Errors.verifyNotZero(token, "token");

        // Checks to make sure pool being priced is not ComposableStablePool.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = token.call(abi.encodeWithSignature("getActualSupply()"));
        if (success) revert InvalidPool(token);

        BalancerUtilities.checkReentrancy(address(balancerVault));

        IBalancerMetaStablePool pool = IBalancerMetaStablePool(token);
        bytes32 poolId = pool.getPoolId();

        // Will revert with BAL#500 on invalid pool id
        // Partial return values are intentionally ignored. This call provides the most efficient way to get the data.
        // slither-disable-next-line unused-return
        (IERC20[] memory tokens,,) = balancerVault.getPoolTokens(poolId);

        // Meta stable vaults only support two tokens, but the vault will resolve any thing
        // Try to verify we're using the right oracle here
        if (tokens.length != 2) {
            revert InvalidTokenCount(token, tokens.length);
        }

        // Use the min price of the tokens
        uint256 px0 = systemRegistry.rootPriceOracle().getPriceInEth(address(tokens[0]));
        uint256 px1 = systemRegistry.rootPriceOracle().getPriceInEth(address(tokens[1]));

        // slither-disable-start divide-before-multiply
        IRateProvider[] memory rateProviders = pool.getRateProviders();
        px0 = px0 * 1e18 / (address(rateProviders[0]) != address(0) ? rateProviders[0].getRate() : 1e18);
        px1 = px1 * 1e18 / (address(rateProviders[1]) != address(0) ? rateProviders[1].getRate() : 1e18);
        // slither-disable-end divide-before-multiply

        // Calculate the virtual price of the pool
        uint256 virtualPrice = BalancerUtilities._getMetaStableVirtualPrice(balancerVault, token);

        price = ((px0 > px1 ? px1 : px0) * virtualPrice) / 1e18;
    }
    // slither-disable-end low-level-calls
    // slither-disable-end missing-zero-check
}
