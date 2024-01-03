pragma solidity 0.6.6;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";
import "./IChainlinkOracle.sol";
import "./ILinkswapPriceOracle.sol";
import "./SafeMathLinkswap.sol";

// sliding window oracle that uses observations collected over a window to provide moving price averages in the past
// `windowSize` with a precision of `windowSize / granularity`
// note this is a singleton oracle and only needs to be deployed once per desired parameters, which
// differs from the simple oracle which must be deployed once per pair.
contract LinkswapPriceOracle is ILinkswapPriceOracle {
    using FixedPoint for *;
    using SafeMath for uint256;

    uint256 public constant PERIOD = 4 hours;
    int256 private constant INT256_MAX = 2**255 - 1;

    address public immutable factory;
    // https://etherscan.io/token/0x514910771af9ca656af840dff83e8264ecf986ca#readContract
    address public immutable linkToken;
    // https://etherscan.io/token/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#readContract
    address public immutable wethToken;
    // https://etherscan.io/token/0x28cb7e841ee97947a86B06fA4090C8451f64c0be#readContract
    address public immutable yflToken;
    // https://etherscan.io/address/0x32dbd3214aC75223e27e575C53944307914F7a90#readContract
    address public immutable linkUsdChainlinkOracle;
    // https://etherscan.io/address/0xF79D6aFBb6dA890132F9D7c355e3015f15F3406F#readContract
    address public immutable wethUsdChainlinkOracle;

    IUniswapV2Pair immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint32 public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(
        address _factory,
        address _linkToken,
        address _wethToken,
        address _yflToken,
        address _linkUsdChainlinkOracle,
        address _wethUsdChainlinkOracle
    ) public {
        require(
            _factory != address(0) &&
                _linkToken != address(0) &&
                _wethToken != address(0) &&
                _yflToken != address(0) &&
                _linkUsdChainlinkOracle != address(0) &&
                _wethUsdChainlinkOracle != address(0),
            "LinkswapPriceOracle: ZERO_ADDRESS"
        );
        factory = _factory;
        linkToken = _linkToken;
        wethToken = _wethToken;
        yflToken = _yflToken;
        linkUsdChainlinkOracle = _linkUsdChainlinkOracle;
        wethUsdChainlinkOracle = _wethUsdChainlinkOracle;
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, _wethToken, _yflToken));
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
    }

    function update() external override {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary
            .currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // don't update unless at least one full period has passed since the last update
        if (timeElapsed < PERIOD) return;

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
    // price in terms of how much amount out is received for the amount in
    function computeAmountOut(
        uint256 priceCumulativeStart,
        uint256 priceCumulativeEnd,
        uint256 timeElapsed,
        uint256 amountIn
    ) private pure returns (uint256 amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn) public view returns (uint256 amountOut) {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, "LinkswapPriceOracle: INVALID_TOKEN");
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

    function calculateTokenAmountFromUsdAmount(address token, uint256 usdAmount)
        external
        view
        override
        returns (uint256)
    {
        if (token == yflToken) {
            int256 usdPerWeth = IChainlinkOracle(wethUsdChainlinkOracle).latestAnswer();
            require(usdPerWeth > 0 && usdPerWeth <= INT256_MAX, "LinkswapPriceOracle: INVALID_USD_PRICE");
            // multiply by 10^18 because WETH has 18 dp
            uint256 wethAmount = usdAmount.mul(10**18) / uint256(usdPerWeth);
            return consult(wethToken, wethAmount);
        } else {
            // get the token's USD price (to 8 dp)
            int256 usdPrice;
            if (token == linkToken) {
                usdPrice = IChainlinkOracle(linkUsdChainlinkOracle).latestAnswer();
            } else if (token == wethToken) {
                usdPrice = IChainlinkOracle(wethUsdChainlinkOracle).latestAnswer();
            } else {
                revert("LinkswapPriceOracle: UNEXPECTED_TOKEN");
            }
            require(usdPrice > 0 && usdPrice <= INT256_MAX, "LinkswapPriceOracle: INVALID_USD_PRICE");
            // multiply by 10^18 because LINK+WETH have 18 dp
            return usdAmount.mul(10**18) / uint256(usdPrice);
        }
    }

    function calculateUsdAmountFromTokenAmount(address token, uint256 tokenAmount)
        external
        view
        override
        returns (uint256)
    {
        // get the token's USD price (to 8 dp)
        int256 usdPrice;
        if (token == linkToken) {
            usdPrice = IChainlinkOracle(linkUsdChainlinkOracle).latestAnswer();
        } else if (token == wethToken) {
            usdPrice = IChainlinkOracle(wethUsdChainlinkOracle).latestAnswer();
        } else {
            revert("LinkswapPriceOracle: UNEXPECTED_TOKEN");
        }
        require(usdPrice > 0 && usdPrice <= INT256_MAX, "LinkswapPriceOracle: INVALID_USD_PRICE");
        // divide by 10^18 because LINK+WETH have 18 dp
        return tokenAmount.mul(uint256(usdPrice)) / (10**18);
    }
}
