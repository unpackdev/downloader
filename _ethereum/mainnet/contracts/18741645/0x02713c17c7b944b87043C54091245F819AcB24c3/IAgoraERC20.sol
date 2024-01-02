// SPDX-License-Identifier: UNLICENSED
// Powered by Agora

pragma solidity ^0.8.21;

import "./IERC20Metadata.sol";
import "./IERC20.sol";

import "./IAgoraERC20Config.sol";

interface IAgoraERC20 is IAgoraERC20Config, IERC20, IERC20Metadata {
    function addLiquidity() external payable returns (address);

    event LiquidityLocked(uint256 lpTokens, uint256 daysLocked);
    event TaxesLowered(
        uint256 previousBuyTax,
        uint256 previousSellTax,
        uint256 newBuyTax,
        uint256 newSellTax
    );
    event LiquidityAdded(
        uint256 tokensSupplied,
        uint256 ethSupplied,
        uint256 lpTokensIssued
    );
    event LimitsRaised(
        uint128 oldBuyLimit,
        uint128 oldSellLimit,
        uint128 oldMaxWallet,
        uint128 newBuyLimit,
        uint128 newSellLimit,
        uint128 newMaxWallet
    );
    event LiquidityBurned(uint256 liquidityBurned);
    event ExternalCallError(uint256);
}
