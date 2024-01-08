// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import "./LowGasSafeMath.sol";
import "./FullMath.sol";
import "./IUniswapLiquidityManager.sol";
import "./FixedPoint128.sol";

// import "./LowGasSafeMath.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library UserPositions {
    using LowGasSafeMath for uint256;

    function getTokensOwedAmount(
        uint256 feeGrowth0,
        uint256 feeGrowth1,
        uint256 liquidity,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1
    ) internal pure returns (uint256 tokensOwed0, uint256 tokensOwed1) {
        tokensOwed0 = FullMath.mulDiv(
            feeGrowthGlobal0.sub(feeGrowth0),
            liquidity,
            FixedPoint128.Q128
        );
        tokensOwed1 = FullMath.mulDiv(
            feeGrowthGlobal1.sub(feeGrowth1),
            liquidity,
            FixedPoint128.Q128
        );
    }

    function getUserAndIndexShares(
        uint256 tokensOwed0,
        uint256 tokensOwed1,
        uint256 feesPercentageIndexFund
    )
        internal
        pure
        returns (
            uint256 indexAmount0,
            uint256 indexAmount1,
            uint256 userAmount0,
            uint256 userAmount1
        )
    {
        indexAmount0 = FullMath.mulDiv(tokensOwed0, feesPercentageIndexFund, 100);
        indexAmount1 = FullMath.mulDiv(tokensOwed1, feesPercentageIndexFund, 100);

        userAmount0 = tokensOwed0.sub(indexAmount0);
        userAmount1 = tokensOwed1.sub(indexAmount1);
    }
}
