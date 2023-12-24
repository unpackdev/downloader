// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./CrossChainPool.sol";
import "./HighCovRatioFeePoolV3.sol";
import "./IAdaptor.sol";
import "./ICrossChainPool.sol";

/**
 * This is a fake Pool that implements swap with swapTokensForCredit and swapCreditForTokens.
 * This lets us verify the behaviour of quoteSwap and swap has not changed in our cross-chain implementation.
 */
contract FakeCrossChainPool is CrossChainPool {
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 /*deadline*/
    ) external override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 haircut) {
        IAsset fromAsset = _assetOf(fromToken);

        (uint256 creditAmount, uint256 haircut1) = _swapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            0
        );

        uint256 haircut2;
        (actualToAmount, haircut2) = _doSwapCreditForTokens(toToken, creditAmount, minimumToAmount, to);

        haircut = haircut1 + haircut2;
        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);
    }

    // Override and pass, to reduce contract size
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view override returns (uint256 finalAmount, uint256 withdrewAmount) {}
}
