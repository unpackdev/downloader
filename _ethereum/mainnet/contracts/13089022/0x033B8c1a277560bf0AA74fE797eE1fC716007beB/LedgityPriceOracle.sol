pragma solidity ^0.6.12;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./ILedgityPriceOracle.sol";
import "./FixedPoint.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./UniswapV2OracleLibrary.sol";

// SPDX-License-Identifier: Unlicensed
contract LedgityPriceOracle is ILedgityPriceOracle, Ownable {
    using FixedPoint for *;
    uint public period = 12 hours;
    IUniswapV2Pair pair;
    address public immutable token0;
    address public immutable token1;
    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    constructor(address pair_) public {
        IUniswapV2Pair _pair = IUniswapV2Pair(pair_);
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        changePeriod(12 hours);
    }

    function update() external override {
        require(tryUpdate(), 'LedgityPriceOracle: PERIOD_NOT_ELAPSED');
    }

    function tryUpdate() public override returns (bool) {
        uint32 timeElapsed = UniswapV2OracleLibrary.currentBlockTimestamp() - blockTimestampLast;
        if (timeElapsed < period) {
            return false;
        }
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
        return true;
    }

    function consult(address token, uint amountIn) external view override returns (uint amountOut) {
        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'LedgityPriceOracle: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

    function changePeriod(uint256 _period) public onlyOwner {
        require(_period > 0, 'LedgityPriceOracle: INVALID_PERIOD');
        period = _period;
        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'LedgityPriceOracle: NO_RESERVES'); // ensure that there's liquidity in the pair
        price0Average = FixedPoint.encode(reserve1).divuq(FixedPoint.encode(reserve0));
        price1Average = FixedPoint.encode(reserve0).divuq(FixedPoint.encode(reserve1));
    }
}
