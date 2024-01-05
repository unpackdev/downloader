// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'FixedSafeMath.sol';
import 'SafeMath.sol';
import 'Normalizer.sol';
import 'IIntegralOracle.sol';
import 'UniswapV2OracleLibrary.sol';

contract IntegralOracle is IIntegralOracle {
    using FixedSafeMath for int256;
    using SafeMath for uint256;
    using Normalizer for uint256;

    address public override owner;
    address public uniswapPair;

    int256 public override price;
    uint32 public override epoch;

    int256 private constant _POINT_FIVE = 5 * 10**17;
    int256 private constant _TWO = 2 * 10**18;
    int256 private constant _FOUR = 4 * 10**18;

    uint8 public override xDecimals;
    uint8 public override yDecimals;

    int256[] private bidExponents;
    int256[] private bidQs;
    int256[] private askExponents;
    int256[] private askQs;

    uint32 public override priceUpdateInterval = 5 minutes;
    uint256 public override price0CumulativeLast;
    uint32 public override blockTimestampLast;

    constructor(uint8 _xDecimals, uint8 _yDecimals) {
        require(_xDecimals <= 100 && _yDecimals <= 100, 'IO_DECIMALS_HIGHER_THAN_100');
        owner = msg.sender;
        xDecimals = _xDecimals;
        yDecimals = _yDecimals;
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'IO_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setUniswapPair(address _uniswapPair) external {
        require(msg.sender == owner, 'IO_FORBIDDEN');
        require(_uniswapPair != address(0), 'IO_ADDRESS_ZERO');
        require(isContract(_uniswapPair), 'IO_UNISWAP_PAIR_MUST_BE_CONTRACT');
        uniswapPair = _uniswapPair;
        emit UniswapPairSet(uniswapPair);

        price0CumulativeLast = IUniswapV2Pair(uniswapPair).price0CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = IUniswapV2Pair(uniswapPair).getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'IO_NO_UNISWAP_RESERVES');
        blockTimestampLast = blockTimestamp;
        emit UniswapPairSet(uniswapPair);
    }

    function setPriceUpdateInterval(uint32 interval) public override {
        require(msg.sender == owner, 'IO_FORBIDDEN');
        require(interval > 0, 'IO_INTERVAL_CANNOT_BE_ZERO');
        priceUpdateInterval = interval;
        emit PriceUpdateIntervalSet(interval);
    }

    function updatePrice() public override returns (uint32 _epoch) {
        if (uniswapPair == address(0)) {
            return epoch;
        }

        (uint256 price0Cumulative, , uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrices(
            uniswapPair
        );

        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed >= priceUpdateInterval) {
            FixedPoint.uq112x112 memory price0Average = FixedPoint.uq112x112(
                uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
            );
            uint256 multiplyBy = xDecimals > yDecimals ? 10**(xDecimals - yDecimals) : 1;
            uint256 divideBy = yDecimals > xDecimals ? 10**(yDecimals - xDecimals) : 1;
            price = int256(uint256(price0Average._x).mul(10**18).mul(multiplyBy).div(divideBy).div(2**112));
            price0CumulativeLast = price0Cumulative;
            blockTimestampLast = blockTimestamp;

            epoch += 1; // overflow is desired
        }

        return epoch;
    }

    function normalizeAmount(uint8 decimals, uint256 amount) internal pure returns (int256 result) {
        result = int256(amount.normalize(decimals));
        require(result >= 0, 'IO_INPUT_OVERFLOW');
    }

    function getParameters()
        external
        view
        override
        returns (
            int256[] memory _bidExponents,
            int256[] memory _bidQs,
            int256[] memory _askExponents,
            int256[] memory _askQs
        )
    {
        _bidExponents = bidExponents;
        _bidQs = bidQs;
        _askExponents = askExponents;
        _askQs = askQs;
    }

    function setParameters(
        int256[] calldata _bidExponents,
        int256[] calldata _bidQs,
        int256[] calldata _askExponents,
        int256[] calldata _askQs
    ) public override {
        require(msg.sender == owner, 'IO_FORBIDDEN');
        require(_bidExponents.length == _bidQs.length, 'IO_LENGTH_MISMATCH');
        require(_askExponents.length == _askQs.length, 'IO_LENGTH_MISMATCH');

        bidExponents = _bidExponents;
        bidQs = _bidQs;
        askExponents = _askExponents;
        askQs = _askQs;

        epoch += 1; // overflow is desired
        emit ParametersSet(epoch, bidExponents, bidQs, askExponents, askQs);
    }

    // TRADE

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore
    ) public view override returns (uint256 yAfter) {
        int256 xAfterInt = normalizeAmount(xDecimals, xAfter);
        int256 xBeforeInt = normalizeAmount(xDecimals, xBefore);
        int256 yBeforeInt = normalizeAmount(yDecimals, yBefore);
        // We define the balances in terms of change from the the beginning of the epoch
        int256 yAfterInt = yBeforeInt.sub(integral(xAfterInt.sub(xBeforeInt)));
        require(yAfterInt >= 0, 'IO_NEGATIVE_Y_BALANCE');
        return uint256(yAfterInt).denormalize(yDecimals);
    }

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore
    ) public view override returns (uint256 xAfter) {
        int256 yAfterInt = normalizeAmount(yDecimals, yAfter);
        int256 xBeforeInt = normalizeAmount(xDecimals, xBefore);
        int256 yBeforeInt = normalizeAmount(yDecimals, yBefore);
        // We define the balances in terms of change from the the beginning of the epoch
        int256 xAfterInt = xBeforeInt.add(integralInverted(yBeforeInt.sub(yAfterInt)));
        require(xAfterInt >= 0, 'IO_NEGATIVE_X_BALANCE');
        return uint256(xAfterInt).denormalize(xDecimals);
    }

    // INTEGRALS

    function integral(int256 q) private view returns (int256) {
        // we are integrating over a curve that represents the order book
        if (q > 0) {
            // integrate over bid orders, our trade can be a bid or an ask
            return integralBid(q);
        } else if (q < 0) {
            // integrate over ask orders, our trade can be a bid or an ask
            return integralAsk(q);
        } else {
            return 0;
        }
    }

    function integralBid(int256 q) private view returns (int256) {
        int256 C = 0;
        for (uint256 i = 1; i < bidExponents.length; i++) {
            // find the corresponding range of prices for the piecewise function  (pPrevious, pCurrent)
            // price * e^(i-1) = price * constant, so we can create a lookup table
            int256 pPrevious = price.f18Mul(bidExponents[i - 1]);
            int256 pCurrent = price.f18Mul(bidExponents[i]);

            // pull the corresponding accumulated quantity up to pPrevious and pCurrent
            int256 qPrevious = bidQs[i - 1];
            int256 qCurrent = bidQs[i];

            // the quantity q falls between the range (pPrevious, pCurrent)
            if (q <= qCurrent) {
                // We've fitted a linear function y = ax + b between the points (pPrevious, qPrevious) and (pCurrent, qCurrent)
                // We use this equation to find the price, p, that corresponds to q
                int256 z = q.sub(qCurrent);
                int256 x = (pCurrent.sub(pPrevious)).f18Mul(z).f18Div(qCurrent.sub(qPrevious));

                int256 p = x.add(pCurrent);
                // evaluate integral from pPrevious to p
                int256 A = _POINT_FIVE.f18Mul(pPrevious.add(p)).f18Mul(q.sub(qPrevious));
                return C.add(A);
            } else {
                // the quantity q exceeds the current range (pPrevious, pCurrent)
                // evaluate integral of entire segment
                int256 A = _POINT_FIVE.f18Mul(pPrevious.add(pCurrent)).f18Mul(qCurrent.sub(qPrevious));
                C = C.add(A);
            }
        }
        // this means we've run out of quantity in our curve's orderbook to satisfy the order quantity
        // this is highly unlikely, but it is possible if the user specifies an extremely large order or
        // the orderbook has gone too far in a single direction
        // but if things are operating correctly, this should almost never happen
        revert('IO_OVERFLOW');
    }

    function integralAsk(int256 q) private view returns (int256) {
        int256 C = 0;
        for (uint256 i = 1; i < askExponents.length; i++) {
            int256 pPrevious = price.f18Mul(askExponents[i - 1]);
            int256 pCurrent = price.f18Mul(askExponents[i]);

            int256 qPrevious = askQs[i - 1];
            int256 qCurrent = askQs[i];

            if (q >= qCurrent) {
                int256 p = (pCurrent.sub(pPrevious)).f18Mul(q.sub(qCurrent)).f18Div(qCurrent.sub(qPrevious)).add(
                    pCurrent
                );
                int256 A = _POINT_FIVE.f18Mul(pPrevious.add(p)).f18Mul(q.sub(qPrevious));
                return C.add(A);
            } else {
                int256 A = _POINT_FIVE.f18Mul(pPrevious.add(pCurrent)).f18Mul(qCurrent.sub(qPrevious));
                C = C.add(A);
            }
        }
        revert('IO_OVERFLOW');
    }

    function integralInverted(int256 s) private view returns (int256) {
        if (s > 0) {
            return integralBidInverted(s);
        } else if (s < 0) {
            return integralAskInverted(s);
        } else {
            return 0;
        }
    }

    function integralBidInverted(int256 s) private view returns (int256) {
        int256 C = 0;
        for (uint256 i = 1; i < bidExponents.length; i++) {
            int256 pPrevious = price.f18Mul(bidExponents[i - 1]);
            int256 pCurrent = price.f18Mul(bidExponents[i]);
            int256 qPrevious = bidQs[i - 1];
            int256 qCurrent = bidQs[i];
            int256 A = _POINT_FIVE.f18Mul(pPrevious.add(pCurrent)).f18Mul(qCurrent.sub(qPrevious));
            if (s <= C.add(A)) {
                int256 c = C.sub(s);
                int256 b = pPrevious;
                int256 a = pCurrent.sub(b);
                int256 d = qCurrent.sub(qPrevious);
                int256 insideSqrt = b.f18Mul(b).sub(_TWO.f18Mul(a).f18Mul(c).f18Div(d));
                int256 sqrt = insideSqrt.f18Sqrt();
                int256 h = (sqrt.sub(b)).f18Mul(d).f18Div(a);
                return qPrevious.add(h);
            } else {
                C = C.add(A);
            }
        }
        revert('IO_OVERFLOW');
    }

    function integralAskInverted(int256 s) private view returns (int256) {
        int256 C = 0;
        for (uint256 i = 1; i < askExponents.length; i++) {
            int256 pPrevious = price.f18Mul(askExponents[i - 1]);
            int256 pCurrent = price.f18Mul(askExponents[i]);
            int256 qPrevious = askQs[i - 1];
            int256 qCurrent = askQs[i];
            int256 A = _POINT_FIVE.f18Mul(pPrevious.add(pCurrent)).f18Mul(qCurrent.sub(qPrevious));
            if (s >= C.add(A)) {
                int256 a = pCurrent.sub(pPrevious);
                int256 d = qCurrent.sub(qPrevious);
                int256 b = pPrevious;
                int256 c = C.sub(s);
                int256 inside = b.f18Mul(b).sub(c.f18Mul(_TWO).f18Mul(a).f18Div(d));
                int256 h = inside.f18Sqrt().sub(b).f18Mul(d).f18Div(a);
                return qPrevious.add(h);
            } else {
                C = C.add(A);
            }
        }
        revert('IO_OVERFLOW');
    }

    // SPOT PRICE

    function getSpotPrice(uint256 xCurrent, uint256 xBefore) public view override returns (uint256 spotPrice) {
        int256 xCurrentInt = normalizeAmount(xDecimals, xCurrent);
        int256 xBeforeInt = normalizeAmount(xDecimals, xBefore);
        int256 spotPriceInt = derivative(xCurrentInt.sub(xBeforeInt));
        require(spotPriceInt >= 0, 'IO_NEGATIVE_SPOT_PRICE');
        return uint256(spotPriceInt);
    }

    // DERIVATIVES

    function derivative(int256 t) public view returns (int256) {
        if (t > 0) {
            return derivativeBid(t);
        } else if (t < 0) {
            return derivativeAsk(t);
        } else {
            return price;
        }
    }

    function derivativeBid(int256 t) public view returns (int256) {
        for (uint256 i = 1; i < bidExponents.length; i++) {
            int256 pPrevious = price.f18Mul(bidExponents[i - 1]);
            int256 pCurrent = price.f18Mul(bidExponents[i]);
            int256 qPrevious = bidQs[i - 1];
            int256 qCurrent = bidQs[i];
            if (t <= qCurrent) {
                return (pCurrent.sub(pPrevious)).f18Mul(t.sub(qCurrent)).f18Div(qCurrent.sub(qPrevious)).add(pCurrent);
            }
        }
        revert('IO_OVERFLOW');
    }

    function derivativeAsk(int256 t) public view returns (int256) {
        for (uint256 i = 1; i < askExponents.length; i++) {
            int256 pPrevious = price.f18Mul(askExponents[i - 1]);
            int256 pCurrent = price.f18Mul(askExponents[i]);
            int256 qPrevious = askQs[i - 1];
            int256 qCurrent = askQs[i];
            if (t >= qCurrent) {
                return (pCurrent.sub(pPrevious)).f18Mul(t.sub(qCurrent)).f18Div(qCurrent.sub(qPrevious)).add(pCurrent);
            }
        }
        revert('IO_OVERFLOW');
    }
}
