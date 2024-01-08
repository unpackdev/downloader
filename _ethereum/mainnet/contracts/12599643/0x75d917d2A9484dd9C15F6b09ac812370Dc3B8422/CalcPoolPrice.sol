pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./UniswapPriceOracle.sol";
import "./IPriceFeeds.sol";

contract CalcPoolPrice {
    uint224 constant Q112 = 2**112;

    using FixedPoint for *;
    using SafeMath for uint;

    UniswapPriceOracle public oracle;

    constructor(address oracle_) {
        oracle = UniswapPriceOracle(oracle_);
    }

    function getPoolPriceAverage(address pair_, address asset) public view returns (FixedPoint.uq112x112 memory) {
        IUniswapV2Pair pair = IUniswapV2Pair(pair_);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        FixedPoint.uq112x112 memory priceAverage;

        if (asset == pair.token0()) {
            priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve1), reserve0));
        } else {
            priceAverage = FixedPoint.uq112x112(uqdiv(encode(reserve0), reserve1));
        }

        return priceAverage;
    }

    function getPoolETHAmount(address asset, uint amountIn) public view returns (uint) {
        address pair = oracle.assetPair(asset);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint power;

        FixedPoint.uq112x112 memory priceAverage = getPoolPriceAverage(pair, asset);
        uint result = priceAverage.mul(amountIn).decode144();

        if (token0 == oracle.WETHToken() || token1 == oracle.WETHToken()) {
            // asset and weth pool
            return result;
        } else {
            // asset and stable coin pool
            if (token0 == asset) {
                power = EIP20Interface(token1).decimals();
                return result.mul(calcPoolCourseInETH(token1)).div(10**power);
            } else {
                power = EIP20Interface(token0).decimals();
                return result.mul(calcPoolCourseInETH(token0)).div(10**power);
            }
        }
    }

    function calcPoolCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(oracle.registry()).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        uint power = EIP20Interface(asset).decimals();
        uint amountIn = 10**power;

        return getPoolETHAmount(asset, amountIn);
    }

    function getPoolCourseInETH(address asset) public view returns (uint) {
        if (asset == Registry(oracle.registry()).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        return calcPoolCourseInETH(asset);
    }

    function getPoolPriceInUSD(address asset) public view returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(oracle.ETHUSDPriceFeed()).latestAnswer());
        uint AssetETHCourse = getPoolCourseInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal view returns (uint224 z) {
        z = uint224(y) * uint224(Q112); // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}