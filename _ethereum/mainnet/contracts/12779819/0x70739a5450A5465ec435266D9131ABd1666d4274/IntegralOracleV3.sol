// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'FixedSafeMath.sol';
import 'SafeMath.sol';
import 'Normalizer.sol';
import 'IIntegralOracleV3.sol';
import 'IERC20.sol';
import 'OracleLibrary.sol';

contract IntegralOracleV3 is IIntegralOracleV3 {
    using FixedSafeMath for int256;
    using SafeMath for int256;
    using SafeMath for uint256;
    using Normalizer for uint256;

    address public override owner;
    address public uniswapPair;
    address public token0;
    address public token1;

    int256 public override price;
    int256 public override minPrice = 0;
    int256 public override maxPrice = type(int256).max;
    uint32 public override epoch;

    int256 private constant _ONE = 10**18;
    int256 private constant _TWO = 2 * 10**18;
    uint128 private _ONE_IN_X;

    uint8 public override xDecimals;
    uint8 public override yDecimals;

    int256[] private bidExponents;
    int256[] private bidQs;
    int256[] private askExponents;
    int256[] private askQs;

    uint32 public override priceUpdateInterval = 2 minutes;
    uint32 public override blockTimestampLast;

    constructor(uint8 _xDecimals, uint8 _yDecimals) {
        require(_xDecimals <= 100 && _yDecimals <= 100, 'IO_DECIMALS_HIGHER_THAN_100');
        owner = msg.sender;
        xDecimals = _xDecimals;
        yDecimals = _yDecimals;
        _ONE_IN_X = uint128(10**xDecimals);
    }

    function isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _blockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
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
        IUniswapV3Pool uniswapV3Pool = IUniswapV3Pool(_uniswapPair);
        require(uniswapV3Pool.liquidity() != 0, 'IO_NO_UNISWAP_LIQUIDITY');

        uniswapPair = _uniswapPair;
        token0 = uniswapV3Pool.token0();
        token1 = uniswapV3Pool.token1();
        require(
            IERC20(token0).decimals() == xDecimals && IERC20(token1).decimals() == yDecimals,
            'IO_INVALID_DECIMALS'
        );
        _updatePrice();
        blockTimestampLast = _blockTimestamp();

        emit UniswapPairSet(uniswapPair);
    }

    function setPriceUpdateInterval(uint32 interval) external override {
        require(msg.sender == owner, 'IO_FORBIDDEN');
        require(interval > 0, 'IO_INTERVAL_CANNOT_BE_ZERO');
        priceUpdateInterval = interval;
        emit PriceUpdateIntervalSet(interval);
    }

    function setPriceBounds(int256 _minPrice, int256 _maxPrice) external override {
        require(msg.sender == owner, 'IO_FORBIDDEN');
        require(_minPrice <= _maxPrice, 'IO_INVALID_BOUNDS');
        minPrice = _minPrice;
        maxPrice = _maxPrice;
        emit PriceBoundsSet(minPrice, maxPrice);
    }

    function updatePrice() external override returns (uint32 _epoch) {
        if (uniswapPair == address(0)) {
            return epoch;
        }

        uint32 blockTimestamp = _blockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed >= priceUpdateInterval) {
            _updatePrice();
            blockTimestampLast = blockTimestamp;

            epoch += 1; // overflow is desired
        }

        return epoch;
    }

    function _updatePrice() internal {
        int24 tick = OracleLibrary.consult(uniswapPair, priceUpdateInterval);
        uint256 uniswapPrice = OracleLibrary.getQuoteAtTick(tick, _ONE_IN_X, token0, token1);
        price = normalizeAmount(yDecimals, uniswapPrice);
        require(price >= minPrice && price <= maxPrice, 'IO_PRICE_OUT_OF_BOUNDS');
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
                int256 X = pPrevious.add(pCurrent).mul(qCurrent.sub(qPrevious)).add(
                    pCurrent.sub(pPrevious).mul(q.sub(qCurrent))
                );
                int256 Y = q.sub(qPrevious);
                int256 Z = qCurrent.sub(qPrevious);
                int256 A = X.mul(Y).div(Z).div(_TWO);
                return C.add(A);
            } else {
                // the quantity q exceeds the current range (pPrevious, pCurrent)
                // evaluate integral of entire segment
                int256 A = pPrevious.add(pCurrent).f18Mul(qCurrent.sub(qPrevious)).div(2);
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
                int256 X = pPrevious.add(pCurrent).mul(qCurrent.sub(qPrevious)).add(
                    pCurrent.sub(pPrevious).mul(q.sub(qCurrent))
                );
                int256 Y = q.sub(qPrevious);
                int256 Z = qCurrent.sub(qPrevious);
                int256 A = X.mul(Y).div(Z).div(_TWO);
                return C.add(A);
            } else {
                int256 A = pPrevious.add(pCurrent).f18Mul(qCurrent.sub(qPrevious)).div(2);
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
        int256 _s = s.add(1);
        int256 C = 0;
        for (uint256 i = 1; i < bidExponents.length; i++) {
            int256 pPrevious = price.f18Mul(bidExponents[i - 1]);
            int256 pCurrent = price.f18Mul(bidExponents[i]);
            int256 qPrevious = bidQs[i - 1];
            int256 qCurrent = bidQs[i];
            int256 A = pPrevious.add(pCurrent).f18Mul(qCurrent.sub(qPrevious)).div(2);
            if (_s <= C.add(A)) {
                int256 c = C.sub(_s);
                int256 b = pPrevious;
                int256 a = pCurrent.sub(b);
                int256 d = qCurrent.sub(qPrevious);
                int256 h = f18SolveQuadratic(a, b, c, d);
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
            int256 A = pPrevious.add(pCurrent).f18Mul(qCurrent.sub(qPrevious)).div(2);
            if (s >= C.add(A)) {
                int256 a = pCurrent.sub(pPrevious);
                int256 d = qCurrent.sub(qPrevious);
                int256 b = pPrevious;
                int256 c = C.sub(s);
                int256 h = f18SolveQuadratic(a, b, c, d);
                return qPrevious.add(h).sub(1);
            } else {
                C = C.add(A);
            }
        }
        revert('IO_OVERFLOW');
    }

    function f18SolveQuadratic(
        int256 A,
        int256 B,
        int256 C,
        int256 D
    ) private pure returns (int256) {
        int256 inside = B.mul(B).sub(_TWO.mul(A).mul(C).div(D));
        int256 sqroot = int256(Math.sqrt(uint256(inside)));
        int256 x = sqroot.sub(B).mul(D).div(A);
        for (uint256 i = 0; i < 16; i++) {
            int256 xPrev = x;
            int256 z = A.mul(x);
            x = z.mul(x).div(2).sub(C.mul(D).mul(_ONE)).div(z.add(B.mul(D)));
            if (x > xPrev) {
                if (x.sub(xPrev) <= int256(1)) {
                    return x;
                }
            } else {
                if (xPrev.sub(x) <= int256(1)) {
                    return x;
                }
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
