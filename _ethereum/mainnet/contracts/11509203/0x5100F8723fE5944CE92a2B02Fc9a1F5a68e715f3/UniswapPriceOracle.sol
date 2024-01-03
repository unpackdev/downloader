pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./PriceOracle.sol";
import "./ErrorReporter.sol";
import "./PTokenInterfaces.sol";
import "./SafeMath.sol";
import "./IPriceFeeds.sol";
import "./UniswapPriceOracleStorage.sol";
import "./Registry.sol";

contract UniswapPriceOracle is UniswapPriceOracleStorage, PriceOracle, OracleErrorReporter {
    using FixedPoint for *;
    using SafeMath for uint;

    Registry public registry;
    address public uniswapFactory;
    address public WETHUniswap;
    address public ETHUSDPriceFeed;

    struct cumulativePrice {
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
        uint price0CumulativePrevious;
        uint price1CumulativePrevious;
        uint32 blockTimestampPrevious;
    }

    mapping(address => cumulativePrice) public cumulativePrices;

    constructor() {}

    function initialize(
        address registry_,
        address uniswapFactory_,
        address WETHUniswap_,
        address ETHUSDPriceFeed_
    )
        public
    {
        require(
            registry == Registry(address(0)) &&
            uniswapFactory == address(0) &&
            WETHUniswap == address(0) &&
            ETHUSDPriceFeed == address(0)
            , "UniswapPriceOracle may only be initialized once"
        );

        registry = Registry(registry_);
        uniswapFactory = uniswapFactory_;
        WETHUniswap = WETHUniswap_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;
    }

    function update(address asset) public returns (uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair(asset));

        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestamp;
        (reserve0, reserve1, blockTimestamp) = pair.getReserves();

        if (reserve0 == 0 || reserve1 == 0) {
            return fail(Error.UPDATE_PRICE, FailureInfo.NO_RESERVES);
        }

        if (!isPeriodElapsed(asset)) {
            return fail(Error.UPDATE_PRICE, FailureInfo.PERIOD_NOT_ELAPSED);
        }

        // check old pool or new
        if (isNewAssetForOracle(asset)) {
            // calc average price using reserves for young pools
            cumulativePrices[asset].price0Average = FixedPoint.uq112x112(uqdiv(encode(reserve1), reserve0));
            cumulativePrices[asset].price1Average = FixedPoint.uq112x112(uqdiv(encode(reserve0), reserve1));
        } else {
            uint32 timeElapsed = blockTimestamp - cumulativePrices[asset].blockTimestampPrevious;

            // overflow is desired, casting never truncates
            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            cumulativePrices[asset].price0Average = FixedPoint.uq112x112(uint224((pair.price0CumulativeLast() - cumulativePrices[asset].price0CumulativePrevious) / timeElapsed));
            cumulativePrices[asset].price1Average = FixedPoint.uq112x112(uint224((pair.price1CumulativeLast() - cumulativePrices[asset].price1CumulativePrevious) / timeElapsed));
        }

        // update data
        cumulativePrices[asset].price0CumulativePrevious = pair.price0CumulativeLast();
        cumulativePrices[asset].price1CumulativePrevious = pair.price1CumulativeLast();
        cumulativePrices[asset].blockTimestampPrevious = blockTimestamp;

        emit PriceUpdated(asset, getCourseInETH(asset));

        return uint(Error.NO_ERROR);
    }

    function getUniswapPair(address asset) public view returns (address) {
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapFactory);
        return factory.getPair(WETHUniswap, asset);
    }

    function getUnderlyingPrice(address pToken) public view override returns (uint) {
        if (pToken == registry.pETH()) {
            return getPriceInUSD(registry.pETH());
        }

        address asset = address(PErc20Interface(pToken).underlying());

        return getPriceInUSD(asset);
    }

    function updateUnderlyingPrice(address pToken) public override returns (uint) {
        if (pToken == registry.pETH()) {
            return uint(Error.NO_ERROR);
        }

        address asset = address(PErc20Interface(pToken).underlying());

        return update(asset);
    }

    // Get the most recent price for a asset in USD with 18 decimals of precision.
    function getPriceInUSD(address asset) public view virtual returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(ETHUSDPriceFeed).latestAnswer());
        uint AssetETHCourse = getCourseInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    function getCourseInETH(address asset) public view returns(uint) {
        if (asset == registry.pETH()) {
            // ether always worth 1
            return 1e18;
        }

        uint power = PTokenInterface(asset).decimals();
        uint amountIn = 10**power;
        uint amountOut;

        address pair = getUniswapPair(asset);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        if (asset == token0) {
            amountOut = cumulativePrices[asset].price0Average.mul(amountIn).decode144();
        } else {
            require(asset == token1, 'Oracle: INVALID_TOKEN');
            amountOut = cumulativePrices[asset].price1Average.mul(amountIn).decode144();
        }

        return amountOut;
    }

    function isNewAssetForOracle(address asset) public view returns (bool) {
        return bool(cumulativePrices[asset].blockTimestampPrevious == 0);
    }

    function isPeriodElapsed(address asset) public view returns (bool) {
        if (isNewAssetForOracle(asset)) {
            return true;
        }

        IUniswapV2Pair pair = IUniswapV2Pair(getUniswapPair(asset));
        ( , , uint32 blockTimestamp) = pair.getReserves();

        uint32 timeElapsed = blockTimestamp - cumulativePrices[asset].blockTimestampPrevious;

        return bool(timeElapsed > PERIOD);
    }

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal view returns (uint224 z) {
        z = uint224(y) * uint224(Q112); // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }

    function _setNewAddresses(
        address registry_,
        address uniswapFactory_,
        address WETHUniswap_,
        address ETHUSDPriceFeed_
    ) external returns (uint) {
        // Check caller = admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_ADDRESSES);
        }

        registry = Registry(registry_);
        uniswapFactory = uniswapFactory_;
        WETHUniswap = WETHUniswap_;
        ETHUSDPriceFeed = ETHUSDPriceFeed_;

        return uint(Error.NO_ERROR);
    }

}