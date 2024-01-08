pragma solidity =0.6.6;

import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";
import "./IUniswapPairsOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairsOracle is Initializable, IUniswapPairsOracle {
    using FixedPoint for *;

    uint256 public constant PERIOD = 6 hours;

    address public factory;

    struct PairPrices {
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    mapping(address => PairPrices) prices;

    function initialize(address _factory) public initializer {
        factory = _factory;
    }

    function pairFor(address tokenA, address tokenB) public view override returns (address) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function addPair(address tokenA, address tokenB) public override returns (bool) {
        IUniswapV2Pair _pair = IUniswapV2Pair(pairFor(tokenA, tokenB));

        require(prices[address(_pair)].blockTimestampLast == 0, "UniswapPairsOracle: Pair already added");

        if (!Address.isContract(address(_pair))) {
            return false;
        }

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = _pair.getReserves();

        if (reserve0 == 0 || reserve1 == 0) {
            return false;
        }

        prices[address(_pair)] = PairPrices({
            price0CumulativeLast: _pair.price0CumulativeLast(), // fetch the current accumulated price value (1 / 0)
            price1CumulativeLast: _pair.price1CumulativeLast(), // fetch the current accumulated price value (0 / 1)
            blockTimestampLast: blockTimestampLast,
            price0Average: FixedPoint.uq112x112(0),
            price1Average: FixedPoint.uq112x112(0)
        });

        return true;
    }

    function update(address pair) external override returns (bool) {
        PairPrices storage pairPrices = prices[pair];

        if (pairPrices.blockTimestampLast == 0) {
            return false;
        }

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - pairPrices.blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) {
            return false;
        }

        (uint256 price0Cumulative,uint256 price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed       
        prices[pair].price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - pairPrices.price0CumulativeLast) / timeElapsed)
        );
        prices[pair].price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - pairPrices.price1CumulativeLast) / timeElapsed)
        );
        prices[pair].price0CumulativeLast = price0Cumulative;
        prices[pair].price1CumulativeLast = price1Cumulative;
        prices[pair].blockTimestampLast = blockTimestamp;

        return true;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address pair, address token, uint256 amountIn)
        external
        override
        view
        returns (uint256 amountOut)
    {
        if (prices[pair].blockTimestampLast == 0) {
            return 0;
        }

        if (token == IUniswapV2Pair(pair).token0()) {
            amountOut = prices[pair].price0Average.mul(amountIn).decode144();
        } else {
            require(token == IUniswapV2Pair(pair).token1(), "UniswapPairsOracle: INVALID_TOKEN");
            amountOut = prices[pair].price1Average.mul(amountIn).decode144();
        }
    }
}
