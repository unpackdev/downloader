// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 2023 Tokemak Ops Ltd. All rights reserved.

pragma solidity 0.8.17;

import "./IERC20Metadata.sol";
import "./IERC20.sol";

import "./SystemComponent.sol";
import "./Errors.sol";
import "./ISystemRegistry.sol";
import "./IBasePool.sol";
import "./IVault.sol";
import "./IAsset.sol";
import "./ISpotPriceOracle.sol";

abstract contract BalancerBaseOracle is SystemComponent, ISpotPriceOracle {
    /// @notice The Balancer Vault that all tokens we're resolving here should reference
    /// @dev BPTs themselves are configured with an immutable vault reference
    IVault public immutable balancerVault;

    error InvalidToken(address token);

    constructor(ISystemRegistry _systemRegistry, IVault _balancerVault) SystemComponent(_systemRegistry) {
        // System registry must be properly initialized first
        Errors.verifyNotZero(address(_systemRegistry.rootPriceOracle()), "rootPriceOracle");
        Errors.verifyNotZero(address(_balancerVault), "_balancerVault");

        balancerVault = _balancerVault;
    }

    function getSpotPrice(
        address token,
        address pool,
        address requestedQuoteToken
    ) public returns (uint256 price, address actualQuoteToken) {
        // 1 unit going in so price is in accurate decimals already
        uint256 amountIn = 10 ** IERC20Metadata(token).decimals();

        bytes32 poolId = IBasePool(pool).getPoolId();

        IVault.BatchSwapStep[] memory steps = new IVault.BatchSwapStep[](1);
        steps[0] = IVault.BatchSwapStep(poolId, 0, 1, amountIn, "");

        // Will revert with BAL#500 on invalid pool id
        // Partial return values are intentionally ignored. This call provides the most efficient way to get the data.
        // slither-disable-next-line unused-return
        (IERC20[] memory tokens,,) = balancerVault.getPoolTokens(poolId);

        uint256 nTokens = tokens.length;
        int256 tokenIndex = -1;
        int256 quoteTokenIndex = -1;
        int256 alternativeQuoteTokenIndex = -1;

        // Find the token and quote token indices
        for (uint256 i = 0; i < nTokens; ++i) {
            address t = address(tokens[i]);

            if (t == token) {
                tokenIndex = int256(i);
            } else if (t == requestedQuoteToken) {
                quoteTokenIndex = int256(i);
            } else if (pool != t) {
                // Pools may include their address as a token, which should not be chosen as quote token.
                alternativeQuoteTokenIndex = int256(i);
            }

            // Break out of the loop if both indices are found.
            if (tokenIndex != -1 && quoteTokenIndex != -1) {
                break;
            }
        }

        if (tokenIndex == -1) revert InvalidToken(token);

        // Use an the alternative quote token if the requested one is not found in the pool.
        if (quoteTokenIndex == -1) {
            quoteTokenIndex = alternativeQuoteTokenIndex;
        }

        // Set the actual quote token based on the found index.
        actualQuoteToken = address(tokens[uint256(quoteTokenIndex)]);

        // Prepare swap parameters.
        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(tokens[uint256(tokenIndex)]));
        assets[1] = IAsset(actualQuoteToken);

        IVault.FundManagement memory funds = IVault.FundManagement(address(this), false, payable(address(this)), false);

        // Perform the batch swap query to get price information.
        int256[] memory assetDeltas = balancerVault.queryBatchSwap(IVault.SwapKind.GIVEN_IN, steps, assets, funds);

        // Calculate the price based on the asset deltas and the pool fee.
        uint256 fee = IBasePool(pool).getSwapFeePercentage();

        // Add swap fee to the price calculation.
        // Balancer Fee is in 1e18.
        price = (uint256(-assetDeltas[1]) * 1e18) / (1e18 - fee);
    }
}
