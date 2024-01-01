// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPancakeV3Factory.sol";
import "./IPancakeSwapMerklVaultGovernance.sol";

import "./CommonLibrary.sol";
import "./OracleLibrary.sol";
import "./PositionValue.sol";

contract PancakeSwapMerklHelper {
    IPancakeNonfungiblePositionManager public immutable positionManager;

    constructor(IPancakeNonfungiblePositionManager positionManager_) {
        require(address(positionManager_) != address(0));
        positionManager = positionManager_;
    }

    function liquidityToTokenAmounts(
        uint128 liquidity,
        IPancakeV3Pool pool,
        uint256 uniV3Nft
    ) external view returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint256[](2);
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = positionManager.positions(uniV3Nft);

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
        (tokenAmounts[0], tokenAmounts[1]) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity
        );
    }

    function tokenAmountsToLiquidity(
        uint256[] memory tokenAmounts,
        IPancakeV3Pool pool,
        uint256 uniV3Nft
    ) external view returns (uint128 liquidity) {
        (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = positionManager.positions(uniV3Nft);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            tokenAmounts[0],
            tokenAmounts[1]
        );
    }

    function tokenAmountsToMaximalLiquidity(
        uint160 sqrtRatioX96,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = LiquidityAmounts.getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 > liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @dev returns with "Invalid Token ID" for non-existent nfts
    function getPoolByNft(uint256 uniV3Nft) public view returns (IPancakeV3Pool pool) {
        (, , address token0, address token1, uint24 fee, , , , , , , ) = positionManager.positions(uniV3Nft);
        pool = IPancakeV3Pool(IPancakeV3Factory(positionManager.factory()).getPool(token0, token1, fee));
    }

    /// @dev returns with "Invalid Token ID" for non-existent nfts
    function getFeesByNft(uint256 uniV3Nft) external view returns (uint256 fees0, uint256 fees1) {
        (fees0, fees1) = PositionValue.fees(positionManager, uniV3Nft);
    }

    /// @dev returns with "Invalid Token ID" for non-existent nfts
    function calculateTvlBySqrtPriceX96(uint256 uniV3Nft, uint160 sqrtPriceX96)
        public
        view
        returns (uint256[] memory tokenAmounts)
    {
        tokenAmounts = new uint256[](2);
        (tokenAmounts[0], tokenAmounts[1]) = PositionValue.total(positionManager, uniV3Nft, sqrtPriceX96);
    }

    /// @dev returns with "Invalid Token ID" for non-existent nfts
    function calculateTvlByMinMaxPrices(
        uint256 uniV3Nft,
        uint256 minPriceX96,
        uint256 maxPriceX96
    ) public view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts) {
        minTokenAmounts = new uint256[](2);
        maxTokenAmounts = new uint256[](2);
        (uint256 fees0, uint256 fees1) = PositionValue.fees(positionManager, uniV3Nft);

        uint160 minSqrtPriceX96 = uint160(CommonLibrary.sqrtX96(minPriceX96));
        uint160 maxSqrtPriceX96 = uint160(CommonLibrary.sqrtX96(maxPriceX96));
        (uint256 amountMin0, uint256 amountMin1) = PositionValue.principal(positionManager, uniV3Nft, minSqrtPriceX96);
        (uint256 amountMax0, uint256 amountMax1) = PositionValue.principal(positionManager, uniV3Nft, maxSqrtPriceX96);

        if (amountMin0 > amountMax0) (amountMin0, amountMax0) = (amountMax0, amountMin0);
        if (amountMin1 > amountMax1) (amountMin1, amountMax1) = (amountMax1, amountMin1);

        minTokenAmounts[0] = amountMin0 + fees0;
        maxTokenAmounts[0] = amountMax0 + fees0;
        minTokenAmounts[1] = amountMin1 + fees1;
        maxTokenAmounts[1] = amountMax1 + fees1;
    }

    function getTickDeviationForTimeSpan(
        int24 tick,
        address pool_,
        uint32 secondsAgo
    ) external view returns (bool withFail, int24 deviation) {
        int24 averageTick;
        (averageTick, , withFail) = OracleLibrary.consult(pool_, secondsAgo);
        deviation = tick - averageTick;
    }

    /// @dev calculates the distribution of tokens that can be added to the position after swap for given capital in token 0
    function getPositionTokenAmountsByCapitalOfToken0(
        uint256 lowerPriceSqrtX96,
        uint256 upperPriceSqrtX96,
        uint256 spotPriceForSqrtFormulasX96,
        uint256 spotPriceX96,
        uint256 capital
    ) external pure returns (uint256 token0Amount, uint256 token1Amount) {
        // sqrt(upperPrice) * (sqrt(price) - sqrt(lowerPrice))
        uint256 lowerPriceTermX96 = FullMath.mulDiv(
            upperPriceSqrtX96,
            spotPriceForSqrtFormulasX96 - lowerPriceSqrtX96,
            CommonLibrary.Q96
        );
        // sqrt(price) * (sqrt(upperPrice) - sqrt(price))
        uint256 upperPriceTermX96 = FullMath.mulDiv(
            spotPriceForSqrtFormulasX96,
            upperPriceSqrtX96 - spotPriceForSqrtFormulasX96,
            CommonLibrary.Q96
        );

        token1Amount = FullMath.mulDiv(
            FullMath.mulDiv(capital, spotPriceX96, CommonLibrary.Q96),
            lowerPriceTermX96,
            lowerPriceTermX96 + upperPriceTermX96
        );

        token0Amount = capital - FullMath.mulDiv(token1Amount, CommonLibrary.Q96, spotPriceX96);
    }

    function getMinMaxPrice(
        address[] memory vaultTokens,
        IOracle oracle,
        uint32 safetyIndicesSet
    ) public view returns (uint256 minPriceX96, uint256 maxPriceX96) {
        (uint256[] memory prices, ) = oracle.priceX96(vaultTokens[0], vaultTokens[1], safetyIndicesSet);
        require(prices.length >= 1, ExceptionsLibrary.INVARIANT);
        minPriceX96 = prices[0];
        maxPriceX96 = prices[0];
        for (uint32 i = 1; i < prices.length; ++i) {
            if (prices[i] < minPriceX96) {
                minPriceX96 = prices[i];
            } else if (prices[i] > maxPriceX96) {
                maxPriceX96 = prices[i];
            }
        }
    }

    function tvl(
        uint256 uniV3Nft_,
        address vaultGovernance_,
        uint256 vaultNft,
        IPancakeV3Pool pool,
        address[] memory vaultTokens
    ) public view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts) {
        if (uniV3Nft_ == 0) {
            return (new uint256[](2), new uint256[](2));
        }

        IPancakeSwapMerklVaultGovernance.DelayedProtocolParams memory params = IPancakeSwapMerklVaultGovernance(
            vaultGovernance_
        ).delayedProtocolParams();
        IPancakeSwapMerklVaultGovernance.DelayedStrategyParams
            memory delayedStrategyParams = IPancakeSwapMerklVaultGovernance(vaultGovernance_).delayedStrategyParams(
                vaultNft
            );
        // cheaper way to calculate tvl by spot price
        if (delayedStrategyParams.safetyIndicesSet == 2) {
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            minTokenAmounts = calculateTvlBySqrtPriceX96(uniV3Nft_, sqrtPriceX96);
            maxTokenAmounts = new uint256[](2);
            maxTokenAmounts[0] = minTokenAmounts[0];
            maxTokenAmounts[1] = minTokenAmounts[1];
        } else {
            (uint256 minPriceX96, uint256 maxPriceX96) = getMinMaxPrice(
                vaultTokens,
                params.oracle,
                delayedStrategyParams.safetyIndicesSet
            );
            (minTokenAmounts, maxTokenAmounts) = calculateTvlByMinMaxPrices(uniV3Nft_, minPriceX96, maxPriceX96);
        }
    }
}
