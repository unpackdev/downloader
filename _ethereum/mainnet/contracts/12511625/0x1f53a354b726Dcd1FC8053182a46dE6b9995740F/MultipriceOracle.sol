// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./IUniswapV3PoolState.sol";
import "./FullMath.sol";
import "./PoolAddress.sol";

import "./IERC20.sol";
import "./IChainlink.sol";
import "./IUniswapV2.sol";
import "./IUniswapV3.sol";

import "./Math.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";

/// @title Multiprice oracle sourcing asset prices from multiple on-chain sources
contract MultipriceOracle {
    using SafeCast for uint256;
    using SafeMath for uint256;

    IChainLinkFeedsRegistry public immutable chainLinkRegistry;
    address public immutable uniswapV3Factory;
    uint24 public immutable uniswapV3PoolFee;
    IUniswapV3CrossPoolOracle public immutable uniswapV3Oracle;
    IUniswapV2Factory public immutable uniswapV2Factory;
    IUniswapV2Factory public immutable sushiswapFactory;
    address public immutable weth;

    mapping(address => bool) public isUsdEquivalent;

    uint256 private constant WEI_UNIT = 10**18;

    constructor(
        IChainLinkFeedsRegistry _chainLinkRegistry,
        address _uniswapV3Factory,
        uint24 _uniswapV3PoolFee,
        IUniswapV3CrossPoolOracle _uniswapV3Oracle,
        IUniswapV2Factory _uniswapV2Factory,
        IUniswapV2Factory _sushiswapFactory,
        address _weth,
        address[] memory _usdEquivalents
    ) {
        chainLinkRegistry = _chainLinkRegistry;
        uniswapV3Factory = _uniswapV3Factory;
        uniswapV3PoolFee = _uniswapV3PoolFee;
        uniswapV3Oracle = _uniswapV3Oracle;
        uniswapV2Factory = _uniswapV2Factory;
        sushiswapFactory = _sushiswapFactory;
        weth = _weth;

        for (uint256 ii = 0; ii < _usdEquivalents.length; ++ii) {
            isUsdEquivalent[_usdEquivalents[ii]] = true;
        }
    }

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _clPriceBuffer,
        uint32 _uniswapV3TwapPeriod,
        uint8 _inclusionBitmap
    )
        external
        view
        returns (
            uint256 value,
            uint256 cl,
            uint256 clBuf,
            uint256 uniV3Twap,
            uint256 uniV3Spot,
            uint256 uniV2Spot,
            uint256 sushiSpot
        )
    {
        // Inclusion bitmap only considers five lowest bits
        require(uint256(_inclusionBitmap) < 1 << 5, 'Inclusion bitmap invalid');

        cl = chainLinkAssetToAsset(_tokenIn, _amountIn, _tokenOut);
        clBuf = cl.mul(WEI_UNIT.sub(_clPriceBuffer)).div(WEI_UNIT);
        uniV3Twap = uniV3TwapAssetToAsset(_tokenIn, _amountIn, _tokenOut, _uniswapV3TwapPeriod);
        uniV3Spot = uniV3SpotAssetToAsset(_tokenIn, _amountIn, _tokenOut);
        uniV2Spot = uniV2SpotAssetToAsset(uniswapV2Factory, _tokenIn, _amountIn, _tokenOut);
        sushiSpot = uniV2SpotAssetToAsset(sushiswapFactory, _tokenIn, _amountIn, _tokenOut);

        uint256[5] memory inclusions = [clBuf, uniV3Twap, uniV3Spot, uniV2Spot, sushiSpot];
        for (uint256 ii = 0; _inclusionBitmap > 0; ) {
            if (_inclusionBitmap % 2 > 0) {
                value = value > 0 ? Math.min(value, inclusions[ii]) : inclusions[ii];
            }

            // Loop bookkeeping
            ++ii;
            _inclusionBitmap >>= 1;
        }
    }

    /********************
     * Chainlink quotes *
     ********************/
    function chainLinkAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        int256 inDecimals = uint256(IERC20(_tokenIn).decimals()).toInt256();
        int256 outDecimals = uint256(IERC20(_tokenOut).decimals()).toInt256();

        if (isUsdEquivalent[_tokenOut]) {
            uint256 rate = chainLinkRegistry.getPriceUSD(_tokenIn);

            // Rate is 0 if the token's feed is not registered
            if (rate > 0) {
                // Adjust decimals for output amount in tokenOut's decimals
                // Rates for usd queries are in 8 decimals
                int256 eFactor = outDecimals - inDecimals - 8;
                return _adjustDecimals(_amountIn.mul(rate), eFactor);
            }
        }

        if (_tokenOut == weth) {
            uint256 rate = chainLinkRegistry.getPriceETH(_tokenIn);

            // Rate is 0 if the token's feed is not registered
            if (rate > 0) {
                // Adjust decimals for output amount in wei
                // Rates for eth queries are in 18 decimals but are cancelled out by wei's 18
                // decimals, leaving just the in decimals to be adjusted for
                int256 eFactor = -inDecimals;
                return _adjustDecimals(_amountIn.mul(rate), eFactor);
            }
        }

        // Try our best to go between two chainlink feeds
        // Messy but tippy-toeing around stack too deeps
        // All four cases covered (token1 price <> token2 price):
        //   1. usd<>usd
        //   2. usd<>eth
        //   3. eth<>eth
        //   4. eth<>usd

        uint256 inUsdRate = chainLinkRegistry.getPriceUSD(_tokenIn);
        uint256 outUsdRate = chainLinkRegistry.getPriceUSD(_tokenOut);
        if (inUsdRate > 0 && outUsdRate > 0) {
            // usd<>usd; both tokens priced in usd terms
            int256 eFactor = outDecimals - inDecimals;
            return _adjustDecimals(_amountIn.mul(inUsdRate).div(outUsdRate), eFactor);
        }

        uint256 inEthRate = chainLinkRegistry.getPriceETH(_tokenIn);
        uint256 outEthRate = chainLinkRegistry.getPriceETH(_tokenOut);
        if (inEthRate > 0 && outEthRate > 0) {
            // eth<>eth; both tokens priced in eth terms
            int256 eFactor = outDecimals - inDecimals;
            return _adjustDecimals(_amountIn.mul(inEthRate).div(outEthRate), eFactor);
        }

        uint256 ethUsdRate = chainLinkRegistry.getPriceUSD(weth);
        if (inUsdRate > 0 && outEthRate > 0) {
            // usd<>eth; convert via amount in -> usd -> eth -> amount out:
            //   amountIn (usd) = amountIn * tokenIn usd rate
            //   amountOut (eth) = amountIn (usd) / eth usd rate
            //   amountOut = amountOut (eth) / tokenOut eth rate
            // Adjust for e-factor first to avoid losing precision from large divisions
            // Usd rates cancel each other, leaving just the 18 decimals from the eth rate and token decimals
            int256 eFactor = outDecimals - inDecimals + 18;
            uint256 adjustedInUsdValue = _adjustDecimals(_amountIn.mul(inUsdRate), eFactor);
            return adjustedInUsdValue.div(ethUsdRate).div(outEthRate);
        }

        if (inEthRate > 0 && outUsdRate > 0) {
            // eth<>usd; convert via amount in -> eth -> usd -> amount out:
            //   amountIn (eth) = amountIn * tokenIn eth rate
            //   amountOut (usd) = amountIn (eth) * eth usd rate
            //   amountOut = amountOut (usd) / tokenOut usd rate
            uint256 unadjustedInUsdValue = _amountIn.mul(inEthRate).mul(ethUsdRate);
            uint256 unadjustedOutAmount = unadjustedInUsdValue.div(outUsdRate); // split div to avoid stack too deep
            // Usd rates cancel each other, leaving just the 18 decimals from the eth rate and token decimals
            int256 eFactor = outDecimals - inDecimals - 18;
            return _adjustDecimals(unadjustedOutAmount, eFactor);
        }

        revert('ChainLink rate not available');
    }

    function _adjustDecimals(uint256 _amount, int256 _eFactor) internal pure returns (uint256) {
        if (_eFactor < 0) {
            uint256 tenToE = 10**uint256(-_eFactor);
            return _amount.div(tenToE);
        } else {
            uint256 tenToE = 10**uint256(_eFactor);
            return _amount.mul(tenToE);
        }
    }

    /*************************
     * UniswapV3 TWAP quotes *
     *************************/
    function uniV3TwapAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) public view returns (uint256 amountOut) {
        return uniswapV3Oracle.assetToAsset(_tokenIn, _amountIn, _tokenOut, _twapPeriod);
    }

    /*************************
     * UniswapV3 spot quotes *
     *************************/
    function uniV3SpotAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        if (_tokenIn == weth) {
            return _uniV3SpotPrice(weth, _amountIn, _tokenOut);
        } else if (_tokenOut == weth) {
            return _uniV3SpotPrice(_tokenIn, _amountIn, weth);
        } else {
            uint256 ethAmount = _uniV3SpotPrice(_tokenIn, _amountIn, weth);
            return _uniV3SpotPrice(weth, ethAmount, _tokenOut);
        }
    }

    function _uniV3SpotPrice(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) internal view returns (uint256 amountOut) {
        address pool =
            PoolAddress.computeAddress(uniswapV3Factory, PoolAddress.getPoolKey(_tokenIn, _tokenOut, uniswapV3PoolFee));
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(pool).slot0();

        // 160 + 160 - 64 = 256; 96 + 96 - 64 = 128
        uint256 priceX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);

        // Pool prices base/quote with lowerToken/higherToken, so adjust for inputs
        return
            _tokenIn < _tokenOut
                ? FullMath.mulDiv(priceX128, _amountIn, 1 << 128)
                : FullMath.mulDiv(1 << 128, _amountIn, priceX128);
    }

    /***********************************
     * UniswapV2/Sushiswap spot quotes *
     ***********************************/
    function uniV2SpotAssetToAsset(
        IUniswapV2Factory _factory,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        if (_tokenIn == weth) {
            return _uniV2SpotEthToAsset(_factory, _amountIn, _tokenOut);
        } else if (_tokenOut == weth) {
            return _uniV2SpotAssetToEth(_factory, _tokenIn, _amountIn);
        } else {
            uint256 ethAmount = _uniV2SpotAssetToEth(_factory, _tokenIn, _amountIn);
            return _uniV2SpotEthToAsset(_factory, ethAmount, _tokenOut);
        }
    }

    function _uniV2SpotAssetToEth(
        IUniswapV2Factory _factory,
        address _tokenIn,
        uint256 _amountIn
    ) internal view returns (uint256 ethAmountOut) {
        address pair = _factory.getPair(_tokenIn, weth);
        (uint256 tokenInReserve, uint256 ethReserve) = UniswapV2Library.getReserves(pair, _tokenIn, weth);
        // No slippage--just spot pricing based on current reserves
        return UniswapV2Library.quote(_amountIn, tokenInReserve, ethReserve);
    }

    function _uniV2SpotEthToAsset(
        IUniswapV2Factory _factory,
        uint256 _ethAmountIn,
        address _tokenOut
    ) internal view returns (uint256 amountOut) {
        address pair = _factory.getPair(weth, _tokenOut);
        (uint256 ethReserve, uint256 tokenOutReserve) = UniswapV2Library.getReserves(pair, weth, _tokenOut);
        // No slippage--just spot pricing based on current reserves
        return UniswapV2Library.quote(_ethAmountIn, ethReserve, tokenOutReserve);
    }
}
