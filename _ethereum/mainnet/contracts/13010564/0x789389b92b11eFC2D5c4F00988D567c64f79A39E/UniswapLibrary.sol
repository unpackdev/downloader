// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./LiquidityAmounts.sol";

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./ABDKMath64x64.sol";
import "./Utils.sol";

/**
 * Helper library for Uniswap functions
 * Used in xAssetCLR
 */
library UniswapLibrary {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint8 private constant TOKEN_DECIMAL_REPRESENTATION = 18;
    uint256 private constant SWAP_SLIPPAGE = 50; // 2%
    uint256 private constant MINT_BURN_SLIPPAGE = 100; // 1%
    uint256 private constant BUFFER_TARGET = 20; // 5% target

    // 1inch v3 exchange address
    address private constant oneInchExchange =
        0x11111112542D85B3EF69AE05771c2dCCff4fAa26;

    struct TokenDetails {
        address token0;
        address token1;
        uint256 token0DecimalMultiplier;
        uint256 token1DecimalMultiplier;
        uint256 tokenDiffDecimalMultiplier;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct PositionDetails {
        uint24 poolFee;
        uint32 twapPeriod;
        uint160 priceLower;
        uint160 priceUpper;
        uint256 tokenId;
        address positionManager;
        address router;
        address pool;
    }

    struct AmountsMinted {
        uint256 amount0ToMint;
        uint256 amount1ToMint;
        uint256 amount0Minted;
        uint256 amount1Minted;
    }

    /* ========================================================================================= */
    /*                                  Uni V3 Pool Helper functions                             */
    /* ========================================================================================= */

    /**
     * @dev Returns the current pool price
     */
    function getPoolPrice(address _pool) public view returns (uint160) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return sqrtRatioX96;
    }

    /**
     * @dev Returns the current pool liquidity
     */
    function getPoolLiquidity(address _pool) public view returns (uint128) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        return pool.liquidity();
    }

    /**
     * @dev Calculate pool liquidity for given token amounts
     */
    function getLiquidityForAmounts(
        uint256 amount0,
        uint256 amount1,
        uint160 priceLower,
        uint160 priceUpper,
        address pool
    ) public view returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            getPoolPrice(pool),
            priceLower,
            priceUpper,
            amount0,
            amount1
        );
    }

    /**
     * @dev Calculate token amounts for given pool liquidity
     */
    function getAmountsForLiquidity(
        uint128 liquidity,
        uint160 priceLower,
        uint160 priceUpper,
        address pool
    ) public view returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            getPoolPrice(pool),
            priceLower,
            priceUpper,
            liquidity
        );
    }

    /**
     * @dev Calculates the amounts deposited/withdrawn from the pool
     * @param amount0 - token0 amount to deposit/withdraw
     * @param amount1 - token1 amount to deposit/withdraw
     */
    function calculatePoolMintedAmounts(
        uint256 amount0,
        uint256 amount1,
        uint160 priceLower,
        uint160 priceUpper,
        address pool
    ) public view returns (uint256 amount0Minted, uint256 amount1Minted) {
        uint128 liquidityAmount =
            getLiquidityForAmounts(
                amount0,
                amount1,
                priceLower,
                priceUpper,
                pool
            );
        (amount0Minted, amount1Minted) = getAmountsForLiquidity(
            liquidityAmount,
            priceLower,
            priceUpper,
            pool
        );
    }

    /**
     *  @dev Get asset 0 twap
     *  @dev Uses Uni V3 oracle, reading the TWAP from twap period
     *  @dev or the earliest oracle observation time if twap period is not set
     */
    function getAsset0Price(
        address pool,
        uint32 twapPeriod,
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 tokenDiffDecimalMultiplier
    ) public view returns (int128) {
        uint32[] memory secondsArray = new uint32[](2);
        // get earliest oracle observation time
        IUniswapV3Pool poolImpl = IUniswapV3Pool(pool);
        uint32 observationTime = getObservationTime(poolImpl);
        uint32 currTimestamp = uint32(block.timestamp);
        uint32 earliestObservationSecondsAgo = currTimestamp - observationTime;
        if (
            twapPeriod == 0 ||
            !Utils.lte(
                currTimestamp,
                observationTime,
                currTimestamp - twapPeriod
            )
        ) {
            // set to earliest observation time if:
            // a) twap period is 0 (not set)
            // b) now - twap period is before earliest observation
            secondsArray[0] = earliestObservationSecondsAgo;
        } else {
            secondsArray[0] = twapPeriod;
        }
        secondsArray[1] = 0;
        (int56[] memory prices, ) = poolImpl.observe(secondsArray);

        int128 twap = Utils.getTWAP(prices, secondsArray[0]);
        if (token1Decimals > token0Decimals) {
            // divide twap by token decimal difference
            twap = ABDKMath64x64.mul(
                twap,
                ABDKMath64x64.divu(1, tokenDiffDecimalMultiplier)
            );
        } else if (token0Decimals > token1Decimals) {
            // multiply twap by token decimal difference
            int128 multiplierFixed =
                ABDKMath64x64.fromUInt(tokenDiffDecimalMultiplier);
            twap = ABDKMath64x64.mul(twap, multiplierFixed);
        }
        return twap;
    }

    /**
     *  @dev Get asset 1 twap
     *  @dev Uses Uni V3 oracle, reading the TWAP from twap period
     *  @dev or the earliest oracle observation time if twap period is not set
     */
    function getAsset1Price(
        address pool,
        uint32 twapPeriod,
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 tokenDiffDecimalMultiplier
    ) public view returns (int128) {
        return
            ABDKMath64x64.inv(
                getAsset0Price(
                    pool,
                    twapPeriod,
                    token0Decimals,
                    token1Decimals,
                    tokenDiffDecimalMultiplier
                )
            );
    }

    /**
     * @dev Returns amount in terms of asset 0
     * @dev amount * asset 1 price
     */
    function getAmountInAsset0Terms(
        uint256 amount,
        address pool,
        uint32 twapPeriod,
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 tokenDiffDecimalMultiplier
    ) public view returns (uint256) {
        return
            ABDKMath64x64.mulu(
                getAsset1Price(
                    pool,
                    twapPeriod,
                    token0Decimals,
                    token1Decimals,
                    tokenDiffDecimalMultiplier
                ),
                amount
            );
    }

    /**
     * @dev Returns amount in terms of asset 1
     * @dev amount * asset 0 price
     */
    function getAmountInAsset1Terms(
        uint256 amount,
        address pool,
        uint32 twapPeriod,
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 tokenDiffDecimalMultiplier
    ) public view returns (uint256) {
        return
            ABDKMath64x64.mulu(
                getAsset0Price(
                    pool,
                    twapPeriod,
                    token0Decimals,
                    token1Decimals,
                    tokenDiffDecimalMultiplier
                ),
                amount
            );
    }

    /**
     * @dev Returns the earliest oracle observation time
     */
    function getObservationTime(IUniswapV3Pool _pool)
        public
        view
        returns (uint32)
    {
        IUniswapV3Pool pool = _pool;
        (, , uint16 index, uint16 cardinality, , , ) = pool.slot0();
        uint16 oldestObservationIndex = (index + 1) % cardinality;
        (uint32 observationTime, , , bool initialized) =
            pool.observations(oldestObservationIndex);
        if (!initialized) (observationTime, , , ) = pool.observations(0);
        return observationTime;
    }

    /**
     * @dev Checks if twap deviates too much from the previous twap
     * @return current twap
     */
    function checkTwap(
        address pool,
        uint32 twapPeriod,
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 tokenDiffDecimalMultiplier,
        int128 lastTwap,
        uint256 maxTwapDeviationDivisor
    ) public view returns (int128) {
        int128 twap =
            getAsset0Price(
                pool,
                twapPeriod,
                token0Decimals,
                token1Decimals,
                tokenDiffDecimalMultiplier
            );
        int128 _lastTwap = lastTwap;
        int128 deviation =
            _lastTwap > twap ? _lastTwap - twap : twap - _lastTwap;
        int128 maxDeviation =
            ABDKMath64x64.mul(
                twap,
                ABDKMath64x64.divu(1, maxTwapDeviationDivisor)
            );
        require(deviation <= maxDeviation, "Wrong twap");
        return twap;
    }

    /**
     * @dev get tick spacing corresponding to pool fee amount
     */
    function getTickSpacingForFee(uint24 fee) public pure returns (int24) {
        if (fee == 500) {
            return 10;
        } else if (fee == 3000) {
            return 60;
        } else if (fee == 10000) {
            return 200;
        } else {
            return 0;
        }
    }

    /* ========================================================================================= */
    /*                              Uni V3 Swap Router Helper functions                          */
    /* ========================================================================================= */

    /**
     * @dev Swap token 0 for token 1 in xAssetCLR contract
     * @dev amountIn and amountOut should be in 18 decimals always
     * @dev amountIn and amountOut are in token 0 terms
     */
    function swapToken0ForToken1(
        uint256 amountIn,
        uint256 amountOut,
        PositionDetails memory positionDetails,
        TokenDetails memory tokenDetails
    ) public returns (uint256 _amountOut) {
        amountOut = getAmountInAsset1Terms(
            amountOut,
            positionDetails.pool,
            positionDetails.twapPeriod,
            tokenDetails.token0Decimals,
            tokenDetails.token1Decimals,
            tokenDetails.tokenDiffDecimalMultiplier
        );
        uint256 token0Balance =
            getBufferToken0Balance(
                IERC20(tokenDetails.token0),
                tokenDetails.token0Decimals,
                tokenDetails.token0DecimalMultiplier
            );
        require(
            token0Balance > amountIn,
            "Swap token 0 for token 1: not enough token 0 balance"
        );

        amountIn = getToken0AmountInNativeDecimals(
            amountIn,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );
        amountOut = getToken1AmountInNativeDecimals(
            amountOut,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );

        ISwapRouter(positionDetails.router).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenDetails.token0,
                tokenOut: tokenDetails.token1,
                fee: positionDetails.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
            })
        );
        return amountOut;
    }

    /**
     * @dev Swap token 1 for token 0 in xAssetCLR contract
     * @dev amountIn and amountOut should be in 18 decimals always
     * @dev amountIn and amountOut are in token 0 terms
     */
    function swapToken1ForToken0(
        uint256 amountIn,
        uint256 amountOut,
        PositionDetails memory positionDetails,
        TokenDetails memory tokenDetails
    ) public returns (uint256 _amountIn) {
        amountIn = getAmountInAsset1Terms(
            amountIn,
            positionDetails.pool,
            positionDetails.twapPeriod,
            tokenDetails.token0Decimals,
            tokenDetails.token1Decimals,
            tokenDetails.tokenDiffDecimalMultiplier
        );
        uint256 token1Balance =
            getBufferToken1Balance(
                IERC20(tokenDetails.token1),
                tokenDetails.token1Decimals,
                tokenDetails.token1DecimalMultiplier
            );
        require(
            token1Balance > amountIn,
            "Swap token 1 for token 0: not enough token 1 balance"
        );

        amountIn = getToken1AmountInNativeDecimals(
            amountIn,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );
        amountOut = getToken0AmountInNativeDecimals(
            amountOut,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );

        ISwapRouter(positionDetails.router).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenDetails.token1,
                tokenOut: tokenDetails.token0,
                fee: positionDetails.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1
            })
        );
        return amountIn;
    }

    /* ========================================================================================= */
    /*                               1inch Swap Helper functions                                 */
    /* ========================================================================================= */

    /**
     * @dev Swap tokens in xAssetCLR using 1inch v3 exchange
     * @param minReturn - required min amount out from swap, in 18 decimals
     * @param _0for1 - swap token0 for token1 if true, token1 for token0 if false
     * @param tokenDetails - xAssetCLR token 0 and token 1 details
     * @param _oneInchData - One inch calldata, generated off-chain from their v3 api for the swap
     */
    function oneInchSwap(
        uint256 minReturn,
        bool _0for1,
        TokenDetails memory tokenDetails,
        bytes memory _oneInchData
    ) public {
        uint256 token0AmtSwapped;
        uint256 token1AmtSwapped;
        bool success;

        // inline code to prevent stack too deep errors
        {
            IERC20 token0 = IERC20(tokenDetails.token0);
            IERC20 token1 = IERC20(tokenDetails.token1);
            uint256 balanceBeforeToken0 = token0.balanceOf(address(this));
            uint256 balanceBeforeToken1 = token1.balanceOf(address(this));

            (success, ) = oneInchExchange.call(_oneInchData);

            require(success, "One inch swap call failed");

            uint256 balanceAfterToken0 = token0.balanceOf(address(this));
            uint256 balanceAfterToken1 = token1.balanceOf(address(this));

            token0AmtSwapped = subAbs(balanceAfterToken0, balanceBeforeToken0);
            token1AmtSwapped = subAbs(balanceAfterToken1, balanceBeforeToken1);
        }

        uint256 amountInSwapped;
        uint256 amountOutReceived;

        if (_0for1) {
            amountInSwapped = getToken0AmountInWei(
                token0AmtSwapped,
                tokenDetails.token0Decimals,
                tokenDetails.token0DecimalMultiplier
            );
            amountOutReceived = getToken1AmountInWei(
                token1AmtSwapped,
                tokenDetails.token1Decimals,
                tokenDetails.token1DecimalMultiplier
            );
        } else {
            amountInSwapped = getToken1AmountInWei(
                token1AmtSwapped,
                tokenDetails.token1Decimals,
                tokenDetails.token1DecimalMultiplier
            );
            amountOutReceived = getToken0AmountInWei(
                token0AmtSwapped,
                tokenDetails.token0Decimals,
                tokenDetails.token0DecimalMultiplier
            );
        }
        // require minimum amount received is > min return
        require(
            amountOutReceived > minReturn,
            "One inch swap not enough output token amount"
        );
    }

    /**
     * Approve 1inch v3 for swaps
     */
    function approveOneInch(IERC20 token0, IERC20 token1) public {
        token0.safeApprove(oneInchExchange, type(uint256).max);
        token1.safeApprove(oneInchExchange, type(uint256).max);
    }

    /* ========================================================================================= */
    /*                               NFT Position Manager Helpers                                */
    /* ========================================================================================= */

    /**
     * @dev Returns the current liquidity in a position represented by tokenId NFT
     */
    function getPositionLiquidity(address positionManager, uint256 tokenId)
        public
        view
        returns (uint128 liquidity)
    {
        (, , , , , , , liquidity, , , , ) = INonfungiblePositionManager(
            positionManager
        )
            .positions(tokenId);
    }

    /**
     * @dev Stake liquidity in position represented by tokenId NFT
     */
    function stake(
        uint256 amount0,
        uint256 amount1,
        address positionManager,
        uint256 tokenId
    ) public returns (uint256 stakedAmount0, uint256 stakedAmount1) {
        (, stakedAmount0, stakedAmount1) = INonfungiblePositionManager(
            positionManager
        )
            .increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0.sub(amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: amount1.sub(amount1.div(MINT_BURN_SLIPPAGE)),
                deadline: block.timestamp
            })
        );
    }

    /**
     * @dev Unstake liquidity from position represented by tokenId NFT
     * @dev using amount0 and amount1 instead of liquidity
     */
    function unstake(
        uint256 amount0,
        uint256 amount1,
        PositionDetails memory positionDetails
    ) public returns (uint256 collected0, uint256 collected1) {
        uint128 liquidityAmount =
            getLiquidityForAmounts(
                amount0,
                amount1,
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
        (uint256 _amount0, uint256 _amount1) =
            unstakePosition(liquidityAmount, positionDetails);
        return
            collectPosition(
                uint128(_amount0),
                uint128(_amount1),
                positionDetails.tokenId,
                positionDetails.positionManager
            );
    }

    /**
     * @dev Unstakes a given amount of liquidity from the Uni V3 position
     * @param liquidity amount of liquidity to unstake
     * @return amount0 token0 amount unstaked
     * @return amount1 token1 amount unstaked
     */
    function unstakePosition(
        uint128 liquidity,
        PositionDetails memory positionDetails
    ) public returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager positionManager =
            INonfungiblePositionManager(positionDetails.positionManager);
        (uint256 _amount0, uint256 _amount1) =
            getAmountsForLiquidity(
                liquidity,
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
        (amount0, amount1) = positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: positionDetails.tokenId,
                liquidity: liquidity,
                amount0Min: _amount0.sub(_amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: _amount1.sub(_amount1.div(MINT_BURN_SLIPPAGE)),
                deadline: block.timestamp
            })
        );
    }

    /**
     *  @dev Collect token amounts from pool position
     */
    function collectPosition(
        uint128 amount0,
        uint128 amount1,
        uint256 tokenId,
        address positionManager
    ) public returns (uint256 collected0, uint256 collected1) {
        (collected0, collected1) = INonfungiblePositionManager(positionManager)
            .collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: amount0,
                amount1Max: amount1
            })
        );
    }

    /**
     * @dev Creates the NFT token representing the pool position
     * @dev Mint initial liquidity
     */
    function createPosition(
        uint256 amount0,
        uint256 amount1,
        address positionManager,
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) public returns (uint256 _tokenId) {
        (_tokenId, , , ) = INonfungiblePositionManager(positionManager).mint(
            INonfungiblePositionManager.MintParams({
                token0: tokenDetails.token0,
                token1: tokenDetails.token1,
                fee: positionDetails.poolFee,
                tickLower: getTickFromPrice(positionDetails.priceLower),
                tickUpper: getTickFromPrice(positionDetails.priceUpper),
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0.sub(amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: amount1.sub(amount1.div(MINT_BURN_SLIPPAGE)),
                recipient: address(this),
                deadline: block.timestamp
            })
        );
    }

    /**
     * @dev burn NFT representing a pool position with tokenId
     * @dev uses NFT Position Manager
     */
    function burn(address positionManager, uint256 tokenId) public {
        INonfungiblePositionManager(positionManager).burn(tokenId);
    }

    /* ========================================================================================= */
    /*                                  xAssetCLR Helpers                                */
    /* ========================================================================================= */

    /**
     * @dev Admin function to stake tokens
     * @dev used in case there's leftover tokens in the contract
     */
    function adminRebalance(
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) public {
        (uint256 token0Balance, uint256 token1Balance) =
            getBufferTokenBalance(tokenDetails);
        token0Balance = getToken0AmountInNativeDecimals(
            token0Balance,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );
        token1Balance = getToken1AmountInNativeDecimals(
            token1Balance,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );
        (uint256 stakeAmount0, uint256 stakeAmount1) =
            checkIfAmountsMatchAndSwap(
                token0Balance,
                token1Balance,
                positionDetails,
                tokenDetails
            );
        require(
            stakeAmount0 != 0 && stakeAmount1 != 0,
            "Rebalance amounts are 0"
        );
        (uint256 amount0, uint256 amount1) =
            calculatePoolMintedAmounts(
                stakeAmount0,
                stakeAmount1,
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
        stake(
            amount0,
            amount1,
            positionDetails.positionManager,
            positionDetails.tokenId
        );
    }

    /**
     * @dev Check if token amounts match before attempting rebalance in xAssetCLR
     * @dev Uniswap contract requires deposits at a precise token ratio
     * @dev If they don't match, swap the tokens so as to deposit as much as possible
     * @param amount0ToMint how much token0 amount we want to deposit/withdraw
     * @param amount1ToMint how much token1 amount we want to deposit/withdraw
     */
    function checkIfAmountsMatchAndSwap(
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        PositionDetails memory positionDetails,
        TokenDetails memory tokenDetails
    ) public returns (uint256 amount0, uint256 amount1) {
        (uint256 amount0Minted, uint256 amount1Minted) =
            calculatePoolMintedAmounts(
                amount0ToMint,
                amount1ToMint,
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
        if (
            amount0Minted <
            amount0ToMint.sub(amount0ToMint.div(MINT_BURN_SLIPPAGE)) ||
            amount1Minted <
            amount1ToMint.sub(amount1ToMint.div(MINT_BURN_SLIPPAGE))
        ) {
            // calculate liquidity ratio =
            // minted liquidity / total pool liquidity
            // used to calculate swap impact in pool
            uint256 mintLiquidity =
                getLiquidityForAmounts(
                    amount0ToMint,
                    amount1ToMint,
                    positionDetails.priceLower,
                    positionDetails.priceUpper,
                    positionDetails.pool
                );
            uint256 poolLiquidity = getPoolLiquidity(positionDetails.pool);
            int128 liquidityRatio =
                poolLiquidity == 0
                    ? 0
                    : int128(ABDKMath64x64.divuu(mintLiquidity, poolLiquidity));
            (amount0, amount1) = restoreTokenRatios(
                liquidityRatio,
                AmountsMinted({
                    amount0ToMint: amount0ToMint,
                    amount1ToMint: amount1ToMint,
                    amount0Minted: amount0Minted,
                    amount1Minted: amount1Minted
                }),
                tokenDetails,
                positionDetails
            );
        } else {
            (amount0, amount1) = (amount0ToMint, amount1ToMint);
        }
    }

    /**
     * @dev Swap tokens in xAssetCLR so as to keep a ratio which is required for
     * @dev depositing/withdrawing liquidity to/from Uniswap pool
     */
    function restoreTokenRatios(
        int128 liquidityRatio,
        AmountsMinted memory amountsMinted,
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) private returns (uint256 amount0, uint256 amount1) {
        // after normalization, returned swap amount will be in wei representation
        uint256 swapAmount;
        {
            int128 asset0Price =
                getAsset0Price(
                    positionDetails.pool,
                    positionDetails.twapPeriod,
                    tokenDetails.token0Decimals,
                    tokenDetails.token1Decimals,
                    tokenDetails.tokenDiffDecimalMultiplier
                );
            // Swap amount returned is always in asset 0 terms
            swapAmount = Utils.calculateSwapAmount(
                Utils.AmountsMinted({
                    amount0ToMint: getToken0AmountInWei(
                        amountsMinted.amount0ToMint,
                        tokenDetails.token0Decimals,
                        tokenDetails.token0DecimalMultiplier
                    ),
                    amount1ToMint: getToken1AmountInWei(
                        amountsMinted.amount1ToMint,
                        tokenDetails.token1Decimals,
                        tokenDetails.token1DecimalMultiplier
                    ),
                    amount0Minted: getToken0AmountInWei(
                        amountsMinted.amount0Minted,
                        tokenDetails.token0Decimals,
                        tokenDetails.token0DecimalMultiplier
                    ),
                    amount1Minted: getToken1AmountInWei(
                        amountsMinted.amount1Minted,
                        tokenDetails.token1Decimals,
                        tokenDetails.token1DecimalMultiplier
                    )
                }),
                liquidityRatio,
                asset0Price
            );
            if (swapAmount == 0) {
                return (
                    amountsMinted.amount0ToMint,
                    amountsMinted.amount1ToMint
                );
            }
        }
        uint256 swapAmountWithSlippage =
            swapAmount.add(swapAmount.div(SWAP_SLIPPAGE));

        uint256 mul1 =
            amountsMinted.amount0ToMint.mul(amountsMinted.amount1Minted);
        uint256 mul2 =
            amountsMinted.amount1ToMint.mul(amountsMinted.amount0Minted);
        (uint256 balance0, uint256 balance1) =
            getBufferTokenBalance(tokenDetails);

        if (mul1 > mul2) {
            if (balance0 < swapAmountWithSlippage) {
                swapAmountWithSlippage = balance0;
            }
            // Swap tokens
            uint256 amountOut =
                swapToken0ForToken1(
                    swapAmountWithSlippage,
                    swapAmount,
                    positionDetails,
                    tokenDetails
                );
            amount0 = amountsMinted.amount0ToMint.sub(
                getToken0AmountInNativeDecimals(
                    swapAmount,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                )
            );
            // amountOut is already in native decimals
            amount1 = amountsMinted.amount1ToMint.add(amountOut);
        } else if (mul1 < mul2) {
            balance1 = getAmountInAsset0Terms(
                balance1,
                positionDetails.pool,
                positionDetails.twapPeriod,
                tokenDetails.token0Decimals,
                tokenDetails.token1Decimals,
                tokenDetails.tokenDiffDecimalMultiplier
            );
            if (balance1 < swapAmountWithSlippage) {
                swapAmountWithSlippage = balance1;
            }
            // Swap tokens
            uint256 amountIn =
                swapToken1ForToken0(
                    swapAmountWithSlippage,
                    swapAmount,
                    positionDetails,
                    tokenDetails
                );
            amount0 = amountsMinted.amount0ToMint.add(
                getToken0AmountInNativeDecimals(
                    swapAmount,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                )
            );
            // amountIn is already in native decimals
            amount1 = amountsMinted.amount1ToMint.sub(amountIn);
        }
    }

    /**
     *  @dev Withdraw *amount* of token 0 or token 1
     *  @param forToken0 withdraw balance for token0 (true) or token1 (false)
     *  @param amount token0 or token1 amount we want to withdraw
     */
    function withdrawSingleToken(
        bool forToken0,
        uint256 amount,
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) private {
        uint256 currBalance;
        uint256 unstakeAmount0;
        uint256 unstakeAmount1;
        uint256 swapAmount;
        IERC20 token0 = IERC20(tokenDetails.token0);
        IERC20 token1 = IERC20(tokenDetails.token1);
        uint256 startBalance =
            forToken0
                ? getBufferToken0Balance(
                    token0,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                )
                : getBufferToken1Balance(
                    token1,
                    tokenDetails.token1Decimals,
                    tokenDetails.token1DecimalMultiplier
                );
        do {
            // calculate how much we can withdraw
            (unstakeAmount0, unstakeAmount1) = calculatePoolMintedAmounts(
                getToken0AmountInNativeDecimals(
                    amount,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                ),
                getToken1AmountInNativeDecimals(
                    amount,
                    tokenDetails.token1Decimals,
                    tokenDetails.token1DecimalMultiplier
                ),
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
            // withdraw both tokens
            unstake(unstakeAmount0, unstakeAmount1, positionDetails);

            // swap the excess amount of token 0 for token 1 or vice-versa
            if (forToken0) {
                // unstakeAmount1 needs to be in token 0 terms
                unstakeAmount1 = getAmountInAsset0Terms(
                    unstakeAmount1,
                    positionDetails.pool,
                    positionDetails.twapPeriod,
                    tokenDetails.token0Decimals,
                    tokenDetails.token1Decimals,
                    tokenDetails.tokenDiffDecimalMultiplier
                );
                swapAmount = getToken1AmountInWei(
                    unstakeAmount1,
                    tokenDetails.token1Decimals,
                    tokenDetails.token1DecimalMultiplier
                );
                swapToken1ForToken0(
                    swapAmount.add(swapAmount.div(SWAP_SLIPPAGE)),
                    swapAmount,
                    positionDetails,
                    tokenDetails
                );
                currBalance = getBufferToken0Balance(
                    token0,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                );
            } else {
                swapAmount = getToken0AmountInWei(
                    unstakeAmount0,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                );
                swapToken0ForToken1(
                    swapAmount.add(swapAmount.div(SWAP_SLIPPAGE)),
                    swapAmount,
                    positionDetails,
                    tokenDetails
                );
                currBalance = getBufferToken1Balance(
                    token1,
                    tokenDetails.token1Decimals,
                    tokenDetails.token1DecimalMultiplier
                );
            }
        } while (currBalance < startBalance.add(amount));
    }

    /**
     * @dev Get token balances in xAssetCLR contract
     * @dev returned balances are in wei representation
     */
    function getBufferTokenBalance(TokenDetails memory tokenDetails)
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        IERC20 token0 = IERC20(tokenDetails.token0);
        IERC20 token1 = IERC20(tokenDetails.token1);
        return (
            getBufferToken0Balance(
                token0,
                tokenDetails.token0Decimals,
                tokenDetails.token0DecimalMultiplier
            ),
            getBufferToken1Balance(
                token1,
                tokenDetails.token1Decimals,
                tokenDetails.token1DecimalMultiplier
            )
        );
    }

    // Get token balances in the position
    function getStakedTokenBalance(
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) public view returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = getAmountsForLiquidity(
            getPositionLiquidity(
                positionDetails.positionManager,
                positionDetails.tokenId
            ),
            positionDetails.priceLower,
            positionDetails.priceUpper,
            positionDetails.pool
        );
        amount0 = getToken0AmountInWei(
            amount0,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );
        amount1 = getToken1AmountInWei(
            amount1,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );
    }

    /**
     * @dev Get token0 balance in xAssetCLR
     */
    function getBufferToken0Balance(
        IERC20 token0,
        uint8 token0Decimals,
        uint256 token0DecimalMultiplier
    ) public view returns (uint256 amount0) {
        return
            getToken0AmountInWei(
                token0.balanceOf(address(this)),
                token0Decimals,
                token0DecimalMultiplier
            );
    }

    /**
     * @dev Get token1 balance in xAssetCLR
     */
    function getBufferToken1Balance(
        IERC20 token1,
        uint8 token1Decimals,
        uint256 token1DecimalMultiplier
    ) public view returns (uint256 amount1) {
        return
            getToken1AmountInWei(
                token1.balanceOf(address(this)),
                token1Decimals,
                token1DecimalMultiplier
            );
    }

    /* ========================================================================================= */
    /*                                       Miscellaneous                                       */
    /* ========================================================================================= */

    /**
     * @dev Returns token0 amount in token0Decimals
     */
    function getToken0AmountInNativeDecimals(
        uint256 amount,
        uint8 token0Decimals,
        uint256 token0DecimalMultiplier
    ) public pure returns (uint256) {
        if (token0Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.div(token0DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev Returns token1 amount in token1Decimals
     */
    function getToken1AmountInNativeDecimals(
        uint256 amount,
        uint8 token1Decimals,
        uint256 token1DecimalMultiplier
    ) public pure returns (uint256) {
        if (token1Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.div(token1DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev Returns token0 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken0AmountInWei(
        uint256 amount,
        uint8 token0Decimals,
        uint256 token0DecimalMultiplier
    ) public pure returns (uint256) {
        if (token0Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.mul(token0DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev Returns token1 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken1AmountInWei(
        uint256 amount,
        uint8 token1Decimals,
        uint256 token1DecimalMultiplier
    ) public pure returns (uint256) {
        if (token1Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.mul(token1DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev get price from tick
     */
    function getSqrtRatio(int24 tick) public pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    /**
     * @dev get tick from price
     */
    function getTickFromPrice(uint160 price) public pure returns (int24) {
        return TickMath.getTickAtSqrtRatio(price);
    }

    /**
     * @dev Subtract two numbers and return absolute value
     */
    function subAbs(uint256 amount0, uint256 amount1)
        public
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0.sub(amount1) : amount1.sub(amount0);
    }

    // Subtract two numbers and return 0 if result is < 0
    function sub0(uint256 amount0, uint256 amount1)
        public
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0.sub(amount1) : 0;
    }

    function calculateFee(uint256 _value, uint256 _feeDivisor)
        public
        pure
        returns (uint256 fee)
    {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }
}
