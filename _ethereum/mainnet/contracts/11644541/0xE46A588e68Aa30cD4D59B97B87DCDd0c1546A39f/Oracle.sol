pragma solidity ^0.6.0;

import "./SafeMath.sol";

import "./Babylonian.sol";
import "./FixedPoint.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";
import "./Epoch.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./ILinkOracle.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract Oracle is Epoch {

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);
    
    using FixedPoint for *;
    using SafeMath for uint256;

    struct PriceData {
        address token0;
        address token1;

        uint    price0CumulativeLast;
        uint    price1CumulativeLast;
        uint32  blockTimestampLast;

        uint price0Average;
        uint price1Average;
    }

    PriceData public priceData;
    IUniswapV2Pair public pair;
    ILinkOracle public linkOracle;

    constructor(
        address _factory,
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _startTime,
        ILinkOracle _linkOracle
    ) public Epoch(_period, _startTime, 0) {
        pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, _tokenA, _tokenB));
        linkOracle = _linkOracle;

        priceData.token0 = pair.token0();
        priceData.token1 = pair.token1();
        priceData.price0CumulativeLast = pair.price0CumulativeLast();
        priceData.price1CumulativeLast = pair.price1CumulativeLast();
        
        uint reserve0;
        uint reserve1;
        (reserve0, reserve1, priceData.blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'Oracle: NO_RESERVES');

        priceData.price0Average = reserve1.mul(1e18).div(reserve0);
        priceData.price1Average = reserve0.mul(1e18).div(reserve1);
    }

    /** @dev Updates 1-day EMA price from Uniswap.  */
    function update() external checkEpoch {
        priceData = priceCurrent();
        emit Updated(priceData.price0CumulativeLast, priceData.price1CumulativeLast);
    }

    function goldPriceOne() external view returns(uint256) {
        return uint256(linkOracle.latestAnswer() * 1e10);
    }

    function price0Last() public view returns (uint amountOut) {
        return priceData.price0Average;
    }

    function price1Last() public view returns (uint amountOut) {
        return priceData.price1Average;
    }

    function price0Current() public view returns (uint amountOut) {
        return priceCurrent().price0Average;
    }

    function price1Current() public view returns (uint amountOut) {
        return priceCurrent().price1Average;
    }

    function blockTimestampLast() external view returns(uint32) {
        return priceData.blockTimestampLast;
    }

    function price0CumulativeLast() external view returns(uint) {
        return priceData.price0CumulativeLast;
    }

    function price1CumulativeLast() external view returns(uint) {
        return priceData.price1CumulativeLast;
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) external pure returns (address lpt) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function priceCurrent() internal view returns(PriceData memory) {
        PriceData memory _priceData = priceData;

        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - _priceData.blockTimestampLast; // overflow is desired

        _priceData.price0Average = uint(
            FixedPoint.uq112x112(
                uint224((price0Cumulative - _priceData.price0CumulativeLast) / timeElapsed)
            ).mul(1e18).decode144()
        );

        _priceData.price1Average = uint(
            FixedPoint.uq112x112(
                uint224((price1Cumulative - _priceData.price1CumulativeLast) / timeElapsed)
            ).mul(1e18).decode144()
        );

        _priceData.price0CumulativeLast = price0Cumulative;
        _priceData.price1CumulativeLast = price1Cumulative;
        _priceData.blockTimestampLast = blockTimestamp;

        return _priceData;
    }
}
