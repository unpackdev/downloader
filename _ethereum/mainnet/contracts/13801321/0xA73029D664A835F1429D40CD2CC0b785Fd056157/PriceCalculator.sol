// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./AdvancedMath.sol";

/**
 * @notice Option price calculator using Black-Scholes formula
 */
library PriceCalculator {
    /// @dev sqrt(365 * 86400)
    int256 internal constant SQRT_YEAR_E8 = 5615.69229926 * 10**8;
    /// @dev range size of linear function
    int256 internal constant RANGE = 20 * 1e6;

    struct Parameters {
        // spot price
        int256 spot;
        // strike price
        int256 strike;
        // log(spot / strike)
        int256 logSigE4;
        // sqrt(maturity)
        int256 sqrtMaturity;
    }

    /**
     * @notice calculate option price at a IV point
     * @param _spot spot price scaled 1e8
     * @param _strike strike price scaled 1e8
     * @param _maturity maturity in seconds
     * @param _iv IV
     * @param _isPut option type
     * @return premium per amount
     */
    function calculatePrice(
        uint256 _spot,
        uint256 _strike,
        uint256 _maturity,
        uint256 _iv,
        bool _isPut
    ) external pure returns (uint256 premium) {
        validateParameters(_spot, _strike);
        require(0 < _iv && _iv < 1000 * 1e6, "PriceCalculator: implied volatility must be between 0 and 1000%");

        int256 sqrtMaturity = getSqrtMaturity(_maturity);
        int256 logSigE4;
        {
            int256 spotPerStrikeE4 = int256((_spot * 1e4) / _strike);
            logSigE4 = AdvancedMath.logTaylor(spotPerStrikeE4);
        }

        return
            uint256(
                calOptionPrice(
                    Parameters(int256(_spot), int256(_strike), logSigE4, sqrtMaturity),
                    int256(_iv),
                    _isPut,
                    // calculatePrice function never reverts by delta cut-off
                    0
                )
            );
    }

    /**
     * @notice calculate option price with two IV points
     * @param _spot spot price scaled 1e8
     * @param _strike strike price scaled 1e8
     * @param _maturity maturity in seconds
     * @param _x0 start IV
     * @param _x1 end IV
     * @param _isPut option type
     * @param _minDelta minimum delta. if delta is less than minDelta or greater than (100% - minDelta), calculation reverts
     * @return premium per amount
     */
    function calculatePrice2(
        uint256 _spot,
        uint256 _strike,
        uint256 _maturity,
        uint256 _x0,
        uint256 _x1,
        bool _isPut,
        uint256 _minDelta
    ) external pure returns (uint256 premium) {
        validateParameters(_spot, _strike);
        require(0 < _x0 && _x0 < 10 * 1e8, "PriceCalculator: 0 < x0 < 1000%");
        require(0 < _x1 && _x1 < 10 * 1e8, "PriceCalculator: 0 < x1 < 1000%");
        require(_x0 < _x1, "PriceCalculator: _x0 < _x1");

        int256 sqrtMaturity = getSqrtMaturity(_maturity);

        int256 logSigE4;
        {
            int256 spotPerStrikeE4 = int256((_spot * 1e4) / _strike);
            logSigE4 = AdvancedMath.logTaylor(spotPerStrikeE4);
        }

        return
            uint256(
                calculatePriceOfRanges(
                    Parameters(int256(_spot), int256(_strike), logSigE4, sqrtMaturity),
                    int256(_x0),
                    int256(_x1),
                    _isPut,
                    _minDelta
                )
            );
    }

    /**
     * @notice calculate option's delta
     * @param _spot spot price scaled 1e8
     * @param _strike strike price scaled 1e8
     * @param sqrtMaturity maturity in seconds
     * @param _iv IV
     * @param _isPut option type
     * @return delta
     */
    function calculateDelta(
        uint256 _spot,
        uint256 _strike,
        int256 sqrtMaturity,
        uint256 _iv,
        bool _isPut
    ) external pure returns (int256) {
        validateParameters(_spot, _strike);
        require(0 < _iv && _iv < 1000 * 1e6, "PriceCalculator: implied volatility must be between 0 and 1000%");

        int256 logSigE4;
        {
            int256 spotPerStrikeE4 = int256((_spot * 1e4) / _strike);
            logSigE4 = AdvancedMath.logTaylor(spotPerStrikeE4);
        }
        (int256 d1E4, ) = _calD1D2(logSigE4, sqrtMaturity, int256(_iv));
        if (_isPut) {
            return -AdvancedMath.calStandardNormalCDF(-d1E4);
        } else {
            return AdvancedMath.calStandardNormalCDF(d1E4);
        }
    }

    function getSqrtMaturity(uint256 _maturity) public pure returns (int256) {
        require(
            _maturity > 0 && _maturity < 31536000,
            "PriceCalculator: maturity must not have expired and less than 1 year"
        );

        return (AdvancedMath.sqrt(int256(_maturity)) * 1e16) / SQRT_YEAR_E8;
    }

    function calculatePriceOfRanges(
        Parameters memory _params,
        int256 _x0,
        int256 _x1,
        bool _isPut,
        uint256 _minDelta
    ) internal pure returns (int256 premium) {
        int256 lower = _x0 / RANGE;
        int256 upper = _x1 / RANGE;
        int256 cache;
        for (int256 i = lower; i <= upper; i++) {
            int256 x0 = 0;
            int256 x1 = RANGE;
            if (i == lower) {
                x0 = _x0 - i * RANGE;
            }
            if (i == upper) {
                x1 = _x1 - i * RANGE;
            }
            int256 p;
            (p, cache) = calculatePriceOfRange(_params, i, x0, x1, _isPut, cache, _minDelta);
            premium += p;
        }
        premium /= upper - lower + 1;
    }

    function calculatePriceOfRange(
        Parameters memory _params,
        int256 _tick,
        int256 _x0,
        int256 _x1,
        bool _isPut,
        int256 _start,
        uint256 _minDelta
    ) internal pure returns (int256, int256) {
        if (_start == 0) {
            _start = calOptionPrice(_params, _tick * RANGE, _isPut, _minDelta);
        }
        int256 end = calOptionPrice(_params, (_tick + 1) * RANGE, _isPut, _minDelta);
        // y = (end - start)/RANGE * x + start + instrict
        return ((_start + ((end - _start) * (_x1 + _x0)) / (2 * RANGE)), end);
    }

    function _calD1D2(
        int256 _logSigE4,
        int256 _sqrtMaturity,
        int256 _volatilityE8
    ) internal pure returns (int256 d1E4, int256 d2E4) {
        int256 sigE8 = (_volatilityE8 * _sqrtMaturity) / (1e8);
        d1E4 = ((_logSigE4 * 10**8) / sigE8) + (sigE8 / (2 * 10**4));
        d2E4 = d1E4 - (sigE8 / 10**4);
    }

    function calOptionPrice(
        Parameters memory _params,
        int256 _volatility,
        bool _isPut,
        uint256 _minDelta
    ) internal pure returns (int256 price) {
        int256 nd1E8;

        if (_volatility > 0) {
            (int256 d1E4, int256 d2E4) = _calD1D2(_params.logSigE4, _params.sqrtMaturity, _volatility);
            nd1E8 = AdvancedMath.calStandardNormalCDF(d1E4);
            int256 nd2E8 = AdvancedMath.calStandardNormalCDF(d2E4);
            price = (_params.spot * nd1E8 - _params.strike * nd2E8) / 1e8;
        }
        int256 lowestPrice;
        if (_isPut) {
            price = price - _params.spot + _params.strike;

            lowestPrice = (_params.strike > _params.spot) ? _params.strike - _params.spot : int256(0);
        } else {
            lowestPrice = (_params.spot > _params.strike) ? _params.spot - _params.strike : int256(0);
        }

        // delta cut-off
        // if option type is put, delta is `1 - N(d1)`
        // if option type is call, delta is `N(d1)`
        require((!_isPut && abs(nd1E8) >= _minDelta) || (_isPut && 1e8 - abs(nd1E8) >= _minDelta), "delta is too low");

        if (price < lowestPrice) {
            return lowestPrice;
        }

        return price;
    }

    function validateParameters(uint256 _spot, uint256 _strike) internal pure {
        require(_spot > 0 && _spot < 1e13, "PriceCalculator: spot price must be between 0 and 10^13");
        require(_strike > 0 && _strike < 1e13, "PriceCalculator: strike price must be between 0 and 10^13");
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
