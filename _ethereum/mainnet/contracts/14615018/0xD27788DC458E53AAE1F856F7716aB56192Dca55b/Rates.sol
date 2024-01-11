pragma solidity 0.7.6;

import "./IRates.sol";
import "./BasicMaths.sol";
import "./UQ112x112.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./SafeCast.sol";
import "./ERC20.sol";

contract Rates is IRates {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using SafeCast for uint256;
    using UQ112x112 for uint224;

    address internal _oraclePool;
    bool internal _reverse;
    uint8 internal _oracle;

    uint32[] private _secondsAgo;
    uint32 private constant OBSERVE_TIME_INTERVAL = 60;
    uint256 private constant E18 = 1e18;
    uint256 private constant E28 = 1e28;
    uint256 private constant E38 = 1e38;
    uint256 private constant E58 = 1e58;
    int256 private precisionDiff = 0;
    uint256 private _priceCumulativeOld;
    uint256 private _priceOld;
    uint32 private _timestampOld;

    constructor(address oraclePool, bool reverse, uint8 oracle) {
        _oraclePool = oraclePool;
        _reverse = reverse;
        _oracle = oracle;
        initPrecisionDiff();

        if (oracle == 0) {
            _secondsAgo = [OBSERVE_TIME_INTERVAL, 0];
        } else {
            _initialPriceV2();
        }
    }

    function initPrecisionDiff() internal {
        address token0;
        address token1;

        if (_oracle == 0) {
            token0 = IUniswapV3Pool(_oraclePool).token0();
            token1 = IUniswapV3Pool(_oraclePool).token1();
        } else {
            token0 = IUniswapV2Pair(_oraclePool).token0();
            token1 = IUniswapV2Pair(_oraclePool).token1();
        }

        precisionDiff =
            int256(ERC20(token0).decimals()) -
            int256(ERC20(token1).decimals());

        if (_oracle != 0 && _reverse) {
            precisionDiff = -precisionDiff;
        }
    }

    function oraclePool() external view override returns (address) {
        return _oraclePool;
    }

    function reverse() external view override returns (bool) {
        return _reverse;
    }

    function getPrice() external view override returns (uint256) {
        return _getPrice();
    }

    function updatePrice() external override {
        require(_oracle != 0, "O Err");

        (uint256 priceCumulativeLast, uint32 blockTimestamp, uint256 price) = _getPriceV2();
        if (blockTimestamp != _timestampOld) {
            _updatePriceV2(priceCumulativeLast, blockTimestamp, price);
        }
    }

    function _getPrice() internal view returns (uint256) {
        if (_oracle == 0) {
            return _getPriceV3();
        } else {
            (, , uint256 price) = _getPriceV2();
            return price;
        }
    }

    function _getPriceAndUpdate() internal returns (uint256) {
        if (_oracle == 0) {
            return _getPriceV3();
        } else {
            (uint256 priceCumulativeLast, uint32 timestampLast, uint256 price) = _getPriceV2();
            if (timestampLast != _timestampOld) {
                _updatePriceV2(priceCumulativeLast, timestampLast, price);
            }

            return price;
        }
    }

    function _getPriceV3() internal view returns (uint256) {
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(_oraclePool).observe(
            _secondsAgo
        );
        uint256 sqrtPriceX96 = uint256(
            TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) /
                    int56(OBSERVE_TIME_INTERVAL))
            )
        );
        uint256 price;
        if (sqrtPriceX96 > E38) {
            price = (sqrtPriceX96 >> 96).mul((sqrtPriceX96.mul(E18)) >> 96);
        } else if (
            precisionDiff > 0 &&
            sqrtPriceX96 < E28.div(10**(uint256(precisionDiff).div(2)))
        ) {
            price =
                (
                    sqrtPriceX96.mul(sqrtPriceX96).mul(E18).mul(
                        10**uint256(precisionDiff)
                    )
                ) >>
                192;
        } else if (sqrtPriceX96 < E28) {
            price = (sqrtPriceX96.mul(sqrtPriceX96).mul(E18)) >> 192;
        } else {
            price = (((sqrtPriceX96.mul(sqrtPriceX96)) >> 96).mul(E18)) >> 96;
        }

        if (precisionDiff > 0) {
            if (sqrtPriceX96 > E28.div(10**(uint256(precisionDiff).div(2)))) {
                price = price.mul(10**uint256(precisionDiff));
            }
        } else if (precisionDiff < 0) {
            price = price.div(10**uint256(-precisionDiff));
        }
        if (price == 0) {
            price = 1;
        }
        if (_reverse) {
            price = _priceReciprocal(price);
        }
        if (price == 0) {
            price = 1;
        }
        return price;
    }

    function _getPriceV2() internal view returns (uint256 priceCumulativeLast, uint32 , uint256 price) {
        IUniswapV2Pair pair = IUniswapV2Pair(_oraclePool);
        (uint112 _reserve0, uint112 _reserve1, uint32 timestampLast) = pair.getReserves();

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        if (blockTimestamp == _timestampOld) {
            return (priceCumulativeLast, blockTimestamp, _priceOld);
        }

        if (_reverse) {
            priceCumulativeLast = pair.price1CumulativeLast();
            if (timestampLast < blockTimestamp) {
                priceCumulativeLast = priceCumulativeLast.add(uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * (blockTimestamp - timestampLast));
            }
        } else {
            priceCumulativeLast = pair.price0CumulativeLast();
            if (timestampLast < blockTimestamp) {
                priceCumulativeLast = priceCumulativeLast.add(uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * (blockTimestamp - timestampLast));
            }
        }

        uint256 priceX112 = priceCumulativeLast.sub(_priceCumulativeOld) / (blockTimestamp - _timestampOld);

        if (priceX112 > E58) {
            price = (priceX112 >> 112).mul(E18);
        } else {
            price = (priceX112.mul(E18)) >> 112;
        }

        if (precisionDiff > 0) {
            price = price.mul(10**uint256(precisionDiff));
        } else {
            price = price / 10**uint256(-precisionDiff);
        }

        if (price == 0) {
            price = 1;
        }

        return (priceCumulativeLast, blockTimestamp, price);
    }

    function _initialPriceV2() internal {
        IUniswapV2Pair pair = IUniswapV2Pair(_oraclePool);
        uint112 reverse0;
        uint112 reverse1;
        (reverse0, reverse1, _timestampOld) = pair.getReserves();
        require(reverse0 > 0 && reverse1 > 0, "not init");

        if (_reverse) {
            _priceCumulativeOld = pair.price1CumulativeLast();
            _priceOld = uint256(reverse0).mul(E18) / reverse1;
        } else {
            _priceCumulativeOld = pair.price0CumulativeLast();
            _priceOld = uint256(reverse1).mul(E18) / reverse0;
        }

        if (precisionDiff > 0) {
            _priceOld = _priceOld.mul(10**uint256(precisionDiff));
        } else {
            _priceOld = _priceOld / 10**uint256(-precisionDiff);
        }
    }

    function _updatePriceV2(uint256 priceCumulativeLast, uint32 timestampLast, uint256 price) internal {
        _priceCumulativeOld = priceCumulativeLast;
        _timestampOld = timestampLast;
        _priceOld = price;
    }

    function _priceReciprocal(uint256 originalPrice)
        internal
        pure
        returns (uint256)
    {
        uint256 one = E18**2;
        uint256 half = originalPrice.div(2);
        return half.add(one).div(originalPrice);
    }
}
